# == Schema Information
#
# Table name: paypal_payments
#
#  created_at         :datetime         not null
#  data               :jsonb            not null
#  id                 :integer          not null, primary key
#  inquiry_id         :integer          not null
#  sale_id            :string
#  sale_status        :string
#  transaction_id     :string           not null
#  transaction_status :string           not null
#  web_token          :string
#
# Indexes
#
#  fk__paypal_payments_inquiry_id           (inquiry_id)
#  index_paypal_payments_on_transaction_id  (transaction_id) UNIQUE
#
# Foreign Keys
#
#  fk_paypal_payments_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => restrict
#

#
# Wir nehmen hier an, dass in `data` genau eine Transaktion mit genau
# einem Sale enthalten ist: In InquiryPaymentMediator#authorize_payment
# wird dies genau so angelegt.
#
class PaypalPayment < ApplicationRecord
  belongs_to :inquiry

  has_many :paypal_webhooks,
    primary_key: :transaction_id,
    foreign_key: :transaction_id

  validates :transaction_id, :transaction_status, :data, presence: true

  before_save :extract_data
  after_save :update_inquiry_payment

  scope :orphaned, -> { where "transaction_status = ? and created_at < ?", "created", 14.days.ago.beginning_of_day }

  def status
    sale_status || transaction_status
  end

  def admin_display_id
    sale_id || transaction_id
  end

  def with_sdk_object(&block)
    return if data.blank?

    sdk_obj = PayPal::SDK::REST::Payment.new(data)

    if block.arity == 2
      yield sdk_obj, sdk_obj.transactions.first
    else
      yield sdk_obj
    end
  end

  def find_sale(paypal_transaction = nil) # rubocop:disable Metrics/CyclomaticComplexity
    paypal_transaction ||= with_sdk_object { |_, tr| tr }

    res = paypal_transaction.related_resources&.find { |rel|
      rel.sale&.is_a? PayPal::SDK::REST::DataTypes::Sale
    }

    return unless (sale = res&.sale)

    block_given? ? yield(sale) : sale
  end

  def payment_amount
    sums[:payment_amount]
  end

  def expected_handling_fee
    sums[:expected_fee]
  end

  def actual_handling_fee
    sums[:actual_fee]
  end

  def surplus
    sums[:expected_fee] - sums[:actual_fee]
  end

  def transaction_sum
    sums[:total_amount]
  end

  def effective_percentage
    100 * (actual_handling_fee - Setting.paypal_fees_absolute) / transaction_sum
  end

  def update_inquiry_payment
    o = with_sdk_object(&:itself)

    payment = inquiry.payments.find_or_initialize_by \
      scope:          "paypal",
      transaction_id: o.id

    payment.paid_on ||= DateTime.parse(o.update_time) if o.update_time
    payment.sum       = payment_amount
    payment.save!
  end

  private

  def extract_data
    with_sdk_object do |o, tr|
      self.transaction_status = o.state
      find_sale(tr) do |s|
        self.sale_id     = s.id
        self.sale_status = s.state
      end
    end

    true
  end

  def sums
    @sums ||= find_sale { |sale|
      amount   = sale.amount
      currency = amount.currency
      {
        total_amount:   Currency::Value.new(amount.total.to_d, currency),
        payment_amount: Currency::Value.new(amount.details.subtotal.to_d, currency),
        expected_fee:   Currency::Value.new(amount.details.handling_fee.to_d, currency),
        actual_fee:     Currency::Value.new((sale.transaction_fee&.value&.presence || 0).to_d, currency),
      }
    } || Hash.new(Currency::Value.new(0.to_d, inquiry.currency))
  end
end
