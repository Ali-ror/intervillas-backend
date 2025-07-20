# == Schema Information
#
# Table name: payments
#
#  created_at           :datetime         not null
#  id                   :integer          not null, primary key
#  inquiry_id           :integer          not null
#  paid_on              :date
#  payment_mail_sent_at :datetime
#  reminder_sent_at     :datetime
#  scope                :string
#  sum                  :decimal(10, 2)   not null
#  transaction_id       :string
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_payments_on_inquiry_id      (inquiry_id)
#  index_payments_on_transaction_id  (transaction_id) UNIQUE
#
# Foreign Keys
#
#  fk_payments_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => cascade
#

class Payment < ApplicationRecord
  SCOPES = [
    "remainder", "downpayment", # deprecated
    "regions_bank", "chase_bank", # ref support#61, support#772
    "spk_hochrhein", "zurich_kb", "paypal_manual", # ref support#24
    "paypal", # ref support#3
    "bsp1",
    "wise", # ref support#706
    "remiss", # ref support#706
  ].freeze

  belongs_to :inquiry

  has_one :paypal_payment, -> { order id: :asc }, # rubocop:disable Rails/InverseOf
    foreign_key: :transaction_id,
    primary_key: :transaction_id

  has_one :bsp1_payment, -> { order id: :asc }, # rubocop:disable Rails/InverseOf
    foreign_key: :txid,
    primary_key: :transaction_id

  delegate :booking, to: :inquiry

  scope :in_year, ->(year) { where("extract('year' from paid_on) = ?", year) }
  scope :paypal, -> { where(scope: "paypal") }
  scope :in_progress, -> { where(paid_on: nil).where("created_at > ?", 1.hour.ago) }
  scope :incoming, -> { where("sum > 0") }

  after_save :book_reservation!

  def book_reservation!
    inquiry.reservation.book! if inquiry.reservation.present? && paid? && sum > 0
  end

  def blank?
    sum.blank? && paid_on.blank?
  end

  def paid?
    sum.present? && sum != 0 && paid_on.present?
  end

  def paid_sum
    paid? ? sum : Currency::Value.new(BigDecimal("0"), inquiry&.currency)
  end

  def sum
    Currency::Value.new(super, inquiry&.currency)
  end

  def direction
    paid_sum > 0 ? "receipt" : "refund"
  end
end
