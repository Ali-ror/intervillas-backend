# == Schema Information
#
# Table name: paypal_webhooks
#
#  created_at     :datetime         not null
#  data           :jsonb            not null
#  event_type     :string           not null
#  id             :integer          not null, primary key
#  status         :string           not null
#  transaction_id :string           not null
#
# Indexes
#
#  index_paypal_webhooks_on_event_type      (event_type)
#  index_paypal_webhooks_on_transaction_id  (transaction_id)
#

class PaypalWebhook < ApplicationRecord
  belongs_to :paypal_payment,
    primary_key: :transaction_id,
    foreign_key: :transaction_id

  has_one :inquiry,
    through: :paypal_payment

  validates :event_type, :transaction_id, :status, :data,
    presence: true

  after_save :update_payments

  def with_sdk_object(&block)
    return if data.blank?

    block.call PayPal::SDK::REST::WebhookEvent.new(data)
  end

  def update_payments
    with_sdk_object { |hook|
      case hook.event_type
      when "PAYMENT.SALE.COMPLETED"
        do_update_payment!(hook.resource["parent_payment"])
        inquiry.messages.create! \
          template:  "payment_mail_reloaded",
          recipient: inquiry.customer

      when "PAYMENT.SALE.PENDING"
        do_update_payment!(hook.resource["parent_payment"])

      when "PAYMENT.SALE.DENIED"
        do_update_payment!(hook.resource["parent_payment"])

        Sentry.capture_message "payment denied", extra: {
          transaction_id: hook.resource["parent_payment"],
          payment_id:     paypal_payment.id,
        }

      else
        # e.g. "PAYMENT.SALE.REFUNDED", "PAYMENT.SALE.REVERSED"
        Sentry.capture_message "unexpected webhook", extra: hook.as_json
      end
    }
  end

  private

  def do_update_payment!(parent)
    ppp = PayPal::SDK::REST::Payment.find(parent)
    paypal_payment.update! data: ppp.as_json
  end
end
