class Api::ContactsController < ApplicationController
  expose(:contact_request) { Digineo::ContactRequest.new(contact_params) }

  def create
    if valid_contact_request?
      ContactMailer.contact_mail(contact_request).deliver_now
      return head :ok
    end

    render :json,
      json:   contact_request.errors,
      status: :unprocessable_entity
  end

  private

  def valid_contact_request?
    contact_request.valid? && valid_recaptcha?
  end

  def valid_recaptcha?
    !require_recaptcha? || verify_recaptcha(model: contact_request, attribute: :captcha)
  end

  def contact_params
    params.require(:contact_request).permit \
      :name,
      :email,
      :phone,
      :text,
      :current_page,
      :villa_id
  end
end
