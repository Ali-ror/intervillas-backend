# == Schema Information
#
# Table name: bsp1_responses
#
#  id         :bigint           not null, primary key
#  balance    :decimal(10, 2)
#  data       :jsonb            not null
#  price      :decimal(10, 2)   not null
#  txaction   :string           not null
#  txid       :string           not null
#  txtime     :bigint           not null
#  created_at :datetime         not null
#  inquiry_id :bigint           not null
#
# Indexes
#
#  index_bsp1_responses_on_inquiry_id  (inquiry_id)
#  index_bsp1_responses_on_txid        (txid)
#
# Foreign Keys
#
#  fk_rails_...  (inquiry_id => inquiries.id)
#

class Bsp1Response < ApplicationRecord
  belongs_to :inquiry

  belongs_to :bsp1_payment_process,
    foreign_key: :txid,
    primary_key: :txid,
    inverse_of:  :bsp1_responses

  has_one :payment,
    foreign_key: :transaction_id,
    primary_key: :txid,
    inverse_of:  :bsp1_payment

  after_commit :update_inquiry_payment,
    on: :create

  scope :finish, -> { where(txaction: [:paid]) }

  def update_inquiry_payment
    case txaction
    when "appointed"
      # Ist lediglich eine Information, dass die Zahlung durchgeführt wird.
      mark_payment_appointed!
    when "paid"
      mark_payment_paid!
    when "debit"
      # Im Merchant-Konto wurde eine Gutschrift getätigt (z.B. NK-Rückzahlung).
      # Wir ignorieren die erstmal, da aus den Transaktionsdaten nicht eindeutig
      # hervorgeht, wie hoch die Rückzahlung war.
      #
      # Beispiel txid 885552941:
      # - balance: 0
      # - price: 8390.00
      # - receivable: 6913
      # - Bei uns hinterlegte Rückzahlung läuft auf USD -1000
      #   (8390 - 6913 == 1477 != 1000)
    else
      Sentry.capture_message "unexpected txaction", extra: data.as_json
    end
  end

  def mark_payment_appointed!
    bsp1_payment_process.update status: "APPOINTED"
  end

  def mark_payment_paid!
    bsp1_payment_process.update status: "PAID"
    payment = inquiry.payments.find_or_initialize_by \
      scope:          "bsp1",
      transaction_id: txid

    calc = PaypalHelper::ChargeCalculator.new :bsp1,
      currency:              inquiry.currency,
      prices_include_cc_fee: inquiry.prices_include_cc_fee
    paid = calc.sub(price).net

    payment.paid_on ||= Time.zone.at(txtime)
    payment.sum       = paid - balance
    payment.save!

    inquiry.messages.create! \
      template:  "payment_mail_reloaded",
      recipient: inquiry.customer
  end
end
