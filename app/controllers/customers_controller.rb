class CustomersController < ApplicationController
  expose :inquiry, before: :new do
    Inquiry.find_by! token: params[:token]
  end

  expose(:villa)    { inquiry.villa }
  expose(:boat)     { inquiry.boat }
  expose(:rentable) { inquiry.rentable }

  expose :customer_form do
    CustomerForms::ForInquiry.from_customer Customer.new(inquiry: inquiry)
  end

  def create
    if customer_form.process(customer_params)
      customer_form.save
      inquiry.send_submission_mail
      session[:tracking_type] = "inquiry"
      session[:tracking_id]   = inquiry.id
      redirect_to :inquiry_processing
    else
      logger.debug { customer_form.errors.full_messages }
      render :new, status: :unprocessable_entity
    end
  end

  private

  def customer_params
    params.require(:customer).permit(%i[locale currency title first_name last_name email email_confirmation newsletter phone])
  end
end
