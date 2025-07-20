class Admin::BillingsController < ApplicationController
  include Admin::ControllerExtensions

  layout "admin_bootstrap"
  load_and_authorize_resource :booking

  before_action :check_admin!

  expose :inquiries do
    Inquiry
      .includes(:villa, :boat, :customer)
      .with_bookings_or_cancellations
      .accessible_by(current_ability)
      .order(id: :desc)
      .paginate(per_page: 20, page: (params[:page] || 1))
  end

  expose(:inquiry, before: :edit) { inquiries.find(params[:id]) }
  expose(:billings)               { inquiries.map(&:to_billing) }
  expose(:billing)                { inquiry.to_billing }
  expose(:booking)                { inquiry.booking unless inquiry.cancelled? }

  # Inquirable#build_billing hätte besser find_or_build_billing heissen sollen.
  expose(:villa_billing)      { inquiry.villa_inquiry&.build_billing }
  expose(:boat_billing)       { inquiry.boat_inquiry&.build_billing }
  expose(:villa_billing_form) { BillingForms::Villa.from_billing(villa_billing) if villa_billing }
  expose(:boat_billing_form)  { BillingForms::Boat.from_billing(boat_billing) if boat_billing }

  expose(:customer_language) do
    customer_locale = booking&.customer&.locale || I18n.default_locale.to_s
    I18n.t(customer_locale, scope: :locales).downcase
  end

  expose(:messages) do
    templates = %w[villa_owner boat_owner owner tenant].map { |b| "#{b}_billing" }
    inquiry.messages.where template: templates
  end

  expose(:villa_owner_message_form) { MessageForm.from_message build_message(:villa) }
  expose(:boat_owner_message_form)  { MessageForm.from_message build_message(:boat) }
  expose(:tenant_message_form)      { MessageForm.from_message build_message(:tenant) }
  expose(:customer_search_form)     { SearchForms::Customer.from_params current_user, {} }

  # Buchungen ohne Abrechnung im letzten halben Jahr
  expose(:invoicables) do
    page = params[:page] || 1
    Inquiry.invoicable.accessible_by(current_ability).paginate(per_page: 20, page: page)
  end

  # zu viel/zu wenig bezahlte Paypal-Gebühren (Info in Sidebar)
  expose(:paypal_surplus) { inquiry.paypal_payments.map { |ppp| ppp.surplus }.sum }

  def update
    form = case params[:billing].delete(:type)
    when "villa" then villa_billing_form
    when "boat"  then boat_billing_form
    else raise ActiveRecord::RecordNotFound
    end

    form.attributes = billing_params

    if form.valid? && form.save
      flash["success"] = "Abrechnung gespeichert."
      redirect_to edit_admin_billing_url(form.bookable)
    else
      flash["error"] = "Fehler beim Speichern der Abrechnung."
      render :edit
    end
  end

  def tenant_billing
    pdf = billing.tenant_billing.pdf
    return unless pdf.save(force: true)

    send_file pdf.file_name,
      type:        "application/pdf",
      disposition: "attachment",
      filename:    "#{pdf.id_string}.pdf"
  end

  def owner_billing
    pdf = billing.owner_billings.find { |ob| ob.owner.id.to_s == params[:owner_id] }.pdf
    return unless pdf.save(force: true)

    send_file pdf.file_name,
      type:        "application/pdf",
      disposition: "attachment",
      filename:    "#{pdf.id_string}.pdf"
  end

  def search_by_id
    params[:id].sub!(/^(?:IV-)?E?/, "") if params.key?(:id)

    redirect_to [:edit, :admin, billing]
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Buchung/Abrechnung Nr. #{params[:id]} nicht gefunden."
    redirect_to %i[admin billings]
  end

  private

  def billing_params
    params.require(:billing).permit(
      :commission,
      :agency_fee,
      :energy_pricing,
      :energy_price,
      :meter_reading_begin,
      :meter_reading_end,
      { charges_attributes: %i[id amount value text _destroy] },
    )
  end

  def build_message(type)
    MessageFactory.build(billing, type)
  end
end
