class Admin::TenantBillingsController < AdminController
  load_and_authorize_resource :booking, instance_name: "admin_booking"
  load_and_authorize_resource :tenant_billing, through: :booking

  before_action :check_admin!
  defaults singleton: true

  belongs_to :booking

  layout false

  expose :tenant_billing do
    resource
  end

  def show
    raise ActiveRecord::RecordNotFound if resource.nil? || resource.new_record?

    send_file resource.to_pdf, type: "application/pdf"
  end

  def create
    super do |success, _failure|
      success.html { redirect_to edit_admin_booking_path(resource.booking_id, anchor: "billing") }
    end
  end

  def update
    super do |success, _failure|
      success.html {
        resource.booking.delete_pdfs
        redirect_to edit_admin_booking_path(resource.booking_id, anchor: "billing")
      }
    end
  end

  private

  def tenant_billing_params
    params.require(:tenant_billing).permit(
      :commission,
      :energy_price,
      :meter_reading_begin,
      :meter_reading_end,
      :owner_message,
      :send_owner_mail,
      :send_tenant_mail,
      :summary_at,
      :tenant_message,
      charges_attributes: %i[
        id
        _destroy
        text
        amount
        value
      ],
    )
  end
end
