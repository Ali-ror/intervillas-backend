class Admin::CustomersController < Admin::BookingsController
  expose(:customer_form) do
    if inquiry.booked?
      if inquiry.external?
        CustomerForms::AdminExternal.from_customer(customer)
      else
        CustomerForms::Admin.from_customer(customer)
      end
    else
      CustomerForms::AdminOffer.from_customer(customer)
    end
  end

  expose(:customer) { Customer.find params[:id] }
  expose(:booking)  { inquiry.booking }
  expose(:inquiry)  { customer.inquiry }

  def update
    if customer_form.process(customer_params)
      customer_form.save
      flash["success"] = t(".success")
      redirect_to [:edit, :admin, redirect_target, { anchor: "customer" }]
    else
      flash["error"] = t(".failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def export
    render csv: Customer.newsletter_export
  end

  private

  def customer_params
    params.require(:customer).permit(%i[
      locale currency title first_name last_name email phone
      address appnr postal_code city country state_code
      bank_account_owner bank_account_number bank_name bank_code
      us_bank_routing_number travel_insurance note
    ])
  end
end
