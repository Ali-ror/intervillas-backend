#
# Gemeinsame Attribute aller Abrechnung-Objekte
#
# - VillaBilling
# - BoatBilling
# - ...
#
module Billable
  extend ActiveSupport::Concern

  included do |base|
    # `rentable` ist "boat" oder "villa", die Kommentare im Folgenden nehmen "boat" an
    class_attribute :rentable, instance_accessor: false
    self.rentable = rentable = base.name.demodulize.underscore.gsub(/_billing\z/, "")

    # boat_inquiry
    x_inquiry = "#{rentable}_inquiry"

    # belongs_to :boat_inquiry, ...
    belongs_to x_inquiry.to_sym,
      foreign_key: :inquiry_id,
      primary_key: :inquiry_id,
      inverse_of:  :billing
    # belongs_to(:rentable_inquiry) == belongs_to(:boat_inquiry), rentable_inquiry == boat_inquiry
    _reflections["rentable_inquiry"] = _reflections[x_inquiry.to_s]
    alias_method :rentable_inquiry, x_inquiry

    # has_one :boat
    has_one rentable.to_sym, through: x_inquiry
    # belongs_to(:rentable) == belongs_to(:boat), rentable == boat
    _reflections["rentable"] = _reflections[rentable.to_s]
    alias_method :rentable, rentable

    belongs_to :inquiry,
      foreign_key: :inquiry_id,
      primary_key: :id

    has_one :booking, through: :inquiry

    has_many :messages,
      foreign_key: :inquiry_id,
      primary_key: :inquiry_id

    has_many :charges

    belongs_to :owner, class_name: "Contact"
    before_validation :set_owner, on: :create

    delegate :clearing,
      to: :inquiry
  end

  def set_owner
    self.owner ||= rentable&.owner
  end

  def positions
    raise NotImplementedError, "must be implemented in sub class"
  end

  def taxes
    raise NotImplementedError, "must be implemented in sub class"
  end

  def rent
    raise NotImplementedError, "must be implemented in sub class"
  end

  # Dummy für BoatBilling
  def pet_fee
    nil
  end

  # Dummy für BoatBilling
  def early_checkin
    nil
  end

  # Dummy für BoatBilling
  def late_checkout
    nil
  end

  def total
    @total ||= begin
      ctx = rentable.class.name.demodulize.underscore.to_sym
      Billing::Position.new :total, ctx, positions.map(&:gross).sum, *rent.taxes.keys
    end
  end

  def agency_commission
    [rent, pet_fee, early_checkin, late_checkout].compact.map(&:net).sum * (commission / 100.0)
  end

  def commission
    super || rentable.owner.try(:commission)
  end

  def tax_identifier(category)
    year = (inquiry&.booking&.summary_on || Date.current).year
    year >= 2019 ? :"#{category}_2019" : category
  end
end
