module Api
  module MyBookingPal
    class ReservationsController < ApplicationController
      skip_forgery_protection
      wrap_parameters false

      # POST /api/my_booking_pal/reservation
      def create
        payload     = params.fetch("reservationNotificationRequest")
        reservation = reservation_class.create_from_payload!(payload)
        create_response :ok,
          id:      reservation.inquiry.number,
          error:   false,
          message: reservation.success_response
      rescue UnsupportedAction => err
        capture_error_and_respond err, "Request action type is not supported",
          status: :internal_server_error
      rescue ActiveRecord::RecordNotFound => err
        capture_error_and_respond err, "Reservation could not be placed: unit not available"
      rescue StandardError => err
        capture_error_and_respond err, "Reservation request could not be processed"
      end

      private

      UnsupportedAction = Class.new ArgumentError
      UnknownAction     = Class.new ArgumentError
      private_constant :UnsupportedAction, :UnknownAction

      def reservation_class
        # params[:action] will always be the controller method name
        action = request.request_parameters[:action]

        case action.downcase
        when "create"
          ::MyBookingPal::Reservation::Create
        when "cancel"
          ::MyBookingPal::Reservation::Cancel
        when "update"
          ::MyBookingPal::Reservation::Update
        when "reservation_request"
          raise UnsupportedAction, "action #{action} is not supported"
        else
          raise UnknownAction, "unknown action: #{action}"
        end
      end

      def create_response(status, id: "", error: false, code: "", message: "")
        render :json, status: status, json: {
          "altId"    => id.to_s,
          "is_error" => error,
          "code"     => code,
          "message"  => message,
        }
      end

      def capture_error_and_respond(err, message, status: :unprocessable_entity)
        Sentry.capture_exception(err)

        uuid = SecureRandom.uuid

        Sidekiq.redis do |conn|
          conn.set "mybookingpal:reservationerrors:#{uuid}", {
            class:   err.class,
            message: err.message,
            payload: request.request_parameters,
          }.to_json, ex: 7.days.to_i
        end

        logger.error "#{err.class} - #{err.message}"
        logger.error err.backtrace.grep_v("/.gems/").slice(0, 10).join("\n")

        create_response status,
          error:   true,
          code:    uuid,
          message: message
      end
    end
  end
end
