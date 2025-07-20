class PaymentsController < ApplicationController
  expose(:inquiry)    { Inquiry.find_by! token: params[:token] }
  expose(:villa)      { inquiry.villa }
  expose(:reservation) { inquiry.reservation_or_booking }
  expose(:deadlines) { reservation.payment_deadlines }

  # Landing-Page mit Informationen zur Zahlung, und Buttons zum Anstoßen des
  # Zahlungsvorgangs
  def index
    redirect_to new_booking_path(token: params[:token]) if reservation.blank?
  end
end
