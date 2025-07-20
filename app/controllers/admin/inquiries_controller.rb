class Admin::InquiriesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include Admin::ControllerExtensions
  include Admin::InquiryTarget

  before_action :check_customer_record, only: [:edit]

  layout "admin_bootstrap"

  expose :inquiries do
    inquiries = Inquiry.complete.order(created_at: :desc)

    unless current_user.admin?
      # `inquiries.accessible_by(current_ability)` funktioniert nicht so richtig...
      inquiries = inquiries.joins(:villa_inquiry, :boat_inquiry).where \
        "villa_inquiries.villa_id in (?) or boat_inquiries.boat_id in (?)",
        current_ability.villa_ids,
        current_ability.boat_ids
    end

    inquiries = inquiries.in_state(params[:state]) if params[:state].present?
    inquiries.paginate(page: params[:page] || 1, per_page: 40)
  end

  expose :inquiry, before: %i[show edit] do
    if params[:id].present?
      Inquiry.find id_from_params
    else
      Inquiry.new
    end
  end

  expose :customer do
    if inquiry.persisted?
      inquiry.customer
    else
      Customer.new
    end
  end

  expose :villa_inquiry do
    # Momentan muss jedes Inquiry auch ein VillaInquiry haben
    # muss später angepasst werden
    if inquiry.persisted?
      inquiry.villa_inquiry
    else
      VillaInquiry.new
    end
  end

  expose(:boat_inquiry)         { inquiry.boat_inquiry }
  expose(:boat_inquiry_form)    { BoatInquiryForms::Admin.from_boat_inquiry boat_inquiry }
  expose(:customer_form)        { CustomerForms::AdminOffer.from_customer(customer) }
  expose(:villa)                { villa_inquiry.villa }
  expose(:customer_search_form) { SearchForms::Customer.from_params current_user, {} }
  expose(:misc_form)            { MiscForms::Inquiry.from_inquiry(inquiry) }

  expose(:adapter)          { ManagerBookingView.new inquiry, admin_inquiries_path }
  expose(:booking_messages) { adapter.messages.where template: "note_mail" }
  expose(:booking_cables)   { current_user.cables_for inquiry }
  expose(:inconsistencies)  { InquiryConsistencyChecker.new(inquiry).inconsistencies }

  expose(:payment_form)          { PaymentForm.from_payment(inquiry.payments.build) }
  expose(:payment_mail_form)     { MessageForm.from_message(build_message("payment_mail_reloaded")) }
  expose(:payment_reminder_form) { MessageForm.from_message(build_message("payment_reminder")) }

  expose(:messages) do
    if current_user.admin?
      [*booking_messages, *booking_cables].sort_by(&:created_at)
    else
      booking_cables
    end
  end

  expose :boats do
    boats = Boat.optionally_assignable.available_between(boat_inquiry.start_date, boat_inquiry.end_date).to_a
    boats << boat_inquiry.boat if boat_inquiry.boat.present? && (boat_inquiry.persisted? || !boat_inquiry.boat.hidden?)
    boats.uniq
  end

  expose :grouped_boats do
    boats
      .group_by { |boat| boat.assigned_to?(villa) ? "dem Haus zugeordnet" : "weitere" }
      .map { |group, boats| [group, boats.map { |boat| [boat.admin_display_name, boat.id] }] }
      .sort_by(&:first)
  end

  def mail
    inquiry.send_submission_mail
    redirect_to action: :edit
  end

  def destroy
    inquiry.destroy
    flash[:success] = "Angebot #{inquiry.number} wurde gelöscht"
    redirect_to admin_inquiries_path
  end

  def update
    misc_form.attributes = resource_params
    if misc_form.valid?
      misc_form.save
      flash["success"] = "Buchungsdaten erfolgreich gespeichert"
      redirect_to [:edit, :admin, redirect_target, { anchor: "misc" }]
    else
      flash["error"] = "Buchungsdaten konnten nicht gespeichert werden"
      render :edit, status: :unprocessable_entity
    end
  end

  def search_by_id
    if current_user.admin?
      # Buchungen/Anfragen, Blockierungen und Stornos teilen sich dieselbe
      # Primary-Key-Sequenz, und Urs möchte natürlich alles finden können
      if (@inquiry = Inquiry.find_by(id: id_from_params))
        redirect_to [:edit, :admin, redirect_target]
        return
      end

      if (blocking = Blocking.find_by(id: id_from_params))
        redirect_to [:edit, :admin, blocking]
        return
      end
    end

    if (booking = Booking.find_by(inquiry_id: id_from_params))
      redirect_to [:admin, booking]
      return
    end

    raise ActiveRecord::RecordNotFound
  end

  def search_name
    @inquiry = Inquiry.search(params[:name]).last
    redirect_to [:edit, :admin, redirect_target]
  end

  private

  def resource_params
    params.require(:inquiry).permit(:comment)
  end

  # entfernt alle nicht-numerischen Zeichen aus params[:id]
  def id_from_params
    params[:id].gsub(/\D/, "")
  end

  def check_customer_record
    raise ActiveRecord::RecordNotFound if inquiry.persisted? && inquiry.customer_id.nil?
  end

  def build_message(type)
    MessageFactory.build(inquiry, type)
  end
end
