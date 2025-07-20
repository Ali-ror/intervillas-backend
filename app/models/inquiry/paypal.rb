module Inquiry::Paypal
  extend ActiveSupport::Concern

  included do
    has_many :paypal_payments
  end

  def create_or_update_paypal_payment!(sdk_payment)
    ppp = paypal_payments.find_or_initialize_by(inquiry_id: id, transaction_id: sdk_payment.id)
    ppp.update! \
      transaction_status: sdk_payment.state,
      web_token:          sdk_payment.token,
      data:               sdk_payment.as_json,
      created_at:         DateTime.parse(sdk_payment.create_time)
  end
end
