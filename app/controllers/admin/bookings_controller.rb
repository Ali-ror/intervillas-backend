class Admin::BookingsController < Admin::InquiriesController
  layout "admin_bootstrap"

  expose :bookings do
    bookings = Booking.accessible_by(current_ability).order(booked_on: :desc)
    bookings = bookings.in_state(params[:state]) if params[:state].present?
    bookings.paginate(page: params[:page] || 1, per_page: 40)
  end

  expose :booking, before: %i[show edit] do
    Booking.find params[:id]
  end

  expose :inquiry, before: %i[show edit] do
    booking.inquiry
  end

  expose(:boat)                 { boat_inquiry.try(:boat) }
  expose(:villa_inquiry)        { inquiry.villa_inquiry }

  expose(:customer_form)        { CustomerForms::Admin.from_inquiry(inquiry) }
  expose(:owner_message_form)   { MessageForm.from_message(build_message(:owner)) }
  expose(:boat_owner_message_form) { MessageForm.from_message(build_message(:boat_owner)) }
  expose(:manager_message_form) { MessageForm.from_message(build_message(:manager)) }
  expose(:misc_form)            { MiscForms::Booking.from_booking(booking) }
  expose(:boat_manager_message_form) { MessageForm.from_message(build_message(:boat_manager)) }
  expose(:customer_form)        { CustomerForms::Admin.from_customer(customer) }

  expose(:cable_form)           { CableForm.from_cable inquiry.cables.build }
  expose(:confirmation_mail)    { inquiry.messages.new template: "confirmation_mail", recipient: customer }

  expose(:adapter)              { ManagerBookingView.new booking, admin_bookings_path }
  expose(:booking_cables)       { current_user.cables_for booking }
  expose(:skipped_travel_mails) { Booking.skipped_travel_mail }

  def show
    authorize! :read, inquiry
    respond_to do |format|
      format.html { render }
    end
  end

  def edit
    authorize! :update, booking
    respond_to do |format|
      format.html { render }
    end
  end

  # Bestätigungsmail versenden
  def mail
    booking.send_confirmation_mail
    flash["success"] = "Mail in den Versand gegeben"
    redirect_to action: :edit
  end

  # Reiseantrittsmail manuell (oder erneut) verschicken
  def travel_mail
    booking.deliver_travel_mail(resend: true)
    flash["success"] = "Mail in den Versand gegeben"
    redirect_to action: :edit
  end

  private

  def resource_params
    params.require(:booking).permit(:comment, :summary_month, :summary_year)
  end

  def build_message(type, subject = nil)
    MessageFactory.build(subject || booking, type)
  end

  def set_locale
    if locale = params[:locale]
      I18n.locale = params[:locale]
    else
      super
    end
  end
end
