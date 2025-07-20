class BookingsController < ApplicationController
  helper_method :customer,
    :downpayment, :downpayment_deadline, :payment_deadline, :remainder
  delegate :customer, to: :inquiry

  expose(:inquiry)        { Inquiry.find_by!(token: params[:token] || params[:id]) }
  expose(:villa_inquiry)  { inquiry.villa_inquiry }
  expose(:villa)          { inquiry.villa }
  expose(:boat_inquiry)   { inquiry.boat_inquiry }
  expose(:boat)           { boat_inquiry.boat }
  expose(:rentable)       { inquiry.rentable }
  expose(:booking)        { inquiry.booking }
  expose(:booking_form)   { BookingForms::Customer.from_inquiry(inquiry, current_user) }
  expose(:clearing)       { inquiry.clearing }
  expose(:villa_clearing) { clearing.for_rentable(:villa) }
  expose(:boat_clearing)  { clearing.for_rentable(:boat) }

  include BookingMailer::Payments

  def new
    if inquiry.booked?
      redirect_to [:confirmation, :booking, { token: inquiry.token }]
      return
    end

    @title = "#{rentable.display_name} - #{t('.title')}"

    render template: "bookings/double_booking" unless inquiry.still_available?
  end

  def redirect_new
    redirect_to action: :new, token: params[:token]
  end

  def create # rubocop:disable Metrics/AbcSize
    @title = "#{rentable.display_name} - #{t('.title')}"

    if booking_form.process(booking_params)
      booking_form.save
      track_booking!(inquiry)
      redirect_to after_inquiry_save_path(inquiry)
    elsif !inquiry.still_available?
      render template: "bookings/double_booking"
    elsif inquiry.reserved?
      render template: "bookings/reserved"
    elsif !inquiry.timely?
      render template: "bookings/not_timely"
    else
      logger.debug { booking_form.errors.full_messages.inspect }
      render :new, status: :unprocessable_entity
    end
  end

  def confirmation
    @title = "#{villa.display_name} - #{t('.title')}"
  end

  private

  def booking_params
    params.require(:booking).permit(:agb, :currency, {
      customer_attributes:  %i[
        address appnr postal_code city country state_code
        bank_account_owner bank_account_number bank_name bank_code
        travel_insurance
      ],
      travelers_attributes: %i[
        id title first_name last_name born_on
      ],
    })
  end

  def set_locale
    if params[:locale].present?
      I18n.locale = params[:locale]
    else
      super
    end
  end

  def track_booking!(inquiry)
    session[:tracking_type] = "booking"
    session[:tracking_id]   = inquiry.id
  end

  def after_inquiry_save_path(inquiry)
    return payments_path(inquiry.token) if inquiry.immediate_payment_required?(current_user)

    :inquiry_processing
  end
end
