# == Schema Information
#
# Table name: boat_billings
#
#  id         :integer          not null, primary key
#  commission :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  inquiry_id :integer          not null
#  owner_id   :bigint           not null
#
# Indexes
#
#  fk__boat_billings_booking_id     (inquiry_id)
#  index_boat_billings_on_owner_id  (owner_id)
#
# Foreign Keys
#
#  fk_boat_billings_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => restrict
#  fk_rails_...                 (owner_id => contacts.id)
#

class BoatBilling < ApplicationRecord
  include Billable

  delegate :start_date, :end_date, :days, :period, :billing_rent,
    to: :boat_inquiry

  def boat_clearing
    @boat_clearing ||= boat_inquiry.clearing
  end

  def positions
    @positions ||= [rent, training]
  end

  def taxes
    @taxes ||= [total.taxes[tax_identifier(:sales)]]
  end

  def rent
    @rent ||= begin
      val = billing_rent || 0
      Billing::Position.new :rent, :boat, val, tax_identifier(:sales)
    end
  end

  def training
    @training ||= begin
      val = boat_clearing.training || 0
      Billing::Position.new :training, :boat, val, tax_identifier(:sales)
    end
  end

  def deposit
    @deposit ||= boat_clearing.total_deposit
  end

  def agency_fee
    0.to_d
  end
end
