# == Schema Information
#
# Table name: charges
#
#  amount           :integer          default(1)
#  boat_billing_id  :integer
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  text             :string           not null
#  updated_at       :datetime         not null
#  value            :decimal(8, 2)    default(0.0)
#  villa_billing_id :integer
#
# Indexes
#
#  fk__charges_boat_billing_id   (boat_billing_id)
#  fk__charges_villa_billing_id  (villa_billing_id)
#
# Foreign Keys
#
#  fk_charges_boat_billing_id   (boat_billing_id => boat_billings.id)
#  fk_charges_villa_billing_id  (villa_billing_id => villa_billings.id)
#

class Charge < ApplicationRecord
  belongs_to :boat_billing, optional: true # optional, weil NULL erlaubt
  belongs_to :villa_billing, optional: true # optional, weil NULL erlaubt

  validates :boat_billing, presence: { if: :boat_billing_id? }
  validates_associated :boat_billing

  validates :villa_billing, presence: { if: :villa_billing_id? }
  validates_associated :villa_billing

  validates :text, presence: true
  validates :amount, presence: true
  validates :value, presence: true

  def sub_total
    amount * value
  end

  def value
    return super if super.nil?

    Currency::Value.new(super, inquiry.currency)
  end

  private

  def inquiry
    villa_billing&.inquiry || boat_billing&.inquiry
  end
end
