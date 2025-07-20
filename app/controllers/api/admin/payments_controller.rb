class Api::Admin::PaymentsController < ApplicationController
  include Admin::ControllerExtensions

  expose(:booking)          { Booking.find params.fetch(:id) }
  expose(:ack_payment_form) { BookingForms::PaymentAcknowledge.from booking }

  def update
    if ack_payment_form.process(booking_params)
      ack_payment_form.save
      render json: { error: false }
    else
      render json: { error: ack_payment_form.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def booking_params
    params.require(:booking).permit(:ack_downpayment)
  end
end
