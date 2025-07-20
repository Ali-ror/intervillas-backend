class Admin::ContactsController < ApplicationController
  include Admin::ControllerExtensions
  include Exposer

  before_action :check_admin!

  layout "admin_bootstrap"

  expose(:collection) do
    Contact.includes(:users).order(last_name: :asc, company_name: :asc)
  end

  expose(:inactive_contacts) do
    Contact.includes(:users).inactive.sort_by { |c| c.last_name.to_s }
  end

  expose(:contact) do
    if %w[new create].include?(action_name)
      collection.build
    else
      collection.find params[:id]
    end
  end

  expose(:basic_contact_form)   { ContactForms::Basics.from_contact(contact) }
  expose(:billing_contact_form) { ContactForms::Billing.from_contact(contact) }
  expose(:bank_account_form)    { ContactForms::BankAccount.from_contact(contact) }

  expose(:current_contact_form) do
    case params[:form]
    when "billing"      then billing_contact_form
    when "bank_account" then bank_account_form
    else basic_contact_form
    end
  end

  # count objects (Villa, Boat) owned or managed by contacts
  expose(:object_count) do
    {
      villa_owner:   Villa.group(:owner_id).count,
      villa_manager: Villa.group(:manager_id).count,
      boat_owner:    Boat.group(:owner_id).count,
      boat_manager:  Boat.group(:manager_id).count,
    }
  end

  # total number of objects owned/managed per contact
  expose(:count_rentables) do
    Hash.new { |h, contact_id|
      h[contact_id] = %i[villa_owner villa_manager boat_owner boat_manager].inject(0) { |sum, kind|
        sum + object_count[kind].fetch(contact_id, 0)
      }
    }
  end

  def new
    render :edit
  end

  def create
    if current_contact_form.process(contact_params)
      current_contact_form.save
      redirect_to [:edit, :admin, contact], notice: "Einstellungen zu «#{contact}» gespeichert."
    else
      render action: :edit, error: "Änderungen an «#{contact}» konnten nicht gespeichert werden."
    end
  end

  alias update create

  def destroy
    if contact.rentables.empty?
      contact.destroy!
      flash[:notice] = "Kontakt «#{contact}» gelöscht."
    else
      flash[:error] = "Kontakt «#{contact}» kann nicht gelöscht werden."
    end

    redirect_to admin_contacts_url
  end

  private

  def contact_params
    params.require(:contact).permit(
      :gender, :company_name, :first_name, :last_name, :address, :city,
      :zip, :country, :phone, :tax_id_number, :commission, :agency_fee, :net,
      :email_addresses, :locale, :wants_auto_booking_confirmation_mail,
      :payout_reminder_days,

      :bank_account_owner,
      :bank_account_number,
      :bank_address,
      :bank_code,
      :bank_name,
      :bank_routing_number,

      :usd_bank_account_owner,
      :usd_bank_account_number,
      :usd_bank_address,
      :usd_bank_code,
      :usd_bank_name,
      :usd_bank_routing_number
    )
  end
end
