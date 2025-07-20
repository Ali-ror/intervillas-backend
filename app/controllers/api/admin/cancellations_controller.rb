class Api::Admin::CancellationsController < ApplicationController
  include Admin::ControllerExtensions
  before_action :check_admin!

  memoize :create_params, private: true do
    params.require(:cancellation).permit(:id, :reason)
  end

  memoize :inquiry, private: true do
    Inquiry.find params.fetch(:id) { create_params.fetch(:id) }
  end

  def create
    inquiry.cancel!(reason: create_params.fetch(:reason))
    render :json, json: {
      index:    admin_bookings_url,
      location: edit_admin_cancellation_url(inquiry), # no redirect
    }
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, status: :not_found
  rescue Inquiry::NotCancellable => err
    render_error err.message
  rescue ActiveRecord::RecordInvalid => err
    render_error err.record.errors.full_messages.join(", ")
  rescue StandardError
    render_error :unknown
  end

  def destroy
    inquiry.uncancel!
    render :json, json: {
      index:    admin_bookings_url,
      location: edit_admin_booking_url(inquiry),
    }
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, status: :not_found
  rescue ActiveRecord::RecordInvalid => err
    render_error err.record.errors.full_messages.join(", ")
  rescue StandardError => err
    logger.warn { [err.class, err.message] }
    render_error :unknown
  end

  private

  def render_error(error, status: :unprocessable_entity)
    error = I18n.t(error, scope: "admin.cancellations.errors") if error.is_a?(Symbol)
    render :json, status: status, json: { error: error }
  end
end
