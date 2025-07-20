#
# Gemeinsame Attribute aller Anfrage-Objekte
#
# - VillaInquiry
# - BoatInquiry
# - ...
#
module Inquirable
  extend ActiveSupport::Concern

  include Dateable

  included do |base|
    # BoatInquiry -> "boat"
    rentable = base.name.demodulize.underscore.gsub(/_inquiry\z/, "")

    base.primary_key = [:inquiry_id, :"#{rentable}_id"]

    # boat_billing
    x_billing = "#{rentable}_billing"

    # belongs_to :boat
    belongs_to rentable.to_sym
    # belongs_to(:rentable) == belongs_to(:boat)
    _reflections["rentable"] = _reflections[rentable.to_s]
    # rentable == boat
    alias_method :rentable, rentable

    # has_one :billing, class_name: "BoatBilling", ...
    has_one :billing,
      foreign_key: :inquiry_id,
      primary_key: :inquiry_id,
      class_name:  x_billing.classify,
      inverse_of:  "#{rentable}_inquiry"

    belongs_to :inquiry
    has_one :booking, through: :inquiry

    scope :booked, -> { joins(:booking) }
    scope :with_currency, ->(curr) { joins(:inquiry).where(inquiries: { currency: curr }) }
    scope :clashes, ->(start_date, end_date) {
      joins(:inquiry)
        .where(inquiries: { cancelled_at: nil })
        .where(base::CLASH_QUERY, start_date: start_date, end_date: end_date)
    }

    scope :in_year, ->(year = Date.current.year) {
      where inquiry_id: InquiryUnion.select(:inquiry_id).distinct.in_year(year)
    }

    delegate :messages, :number,
      to: :inquiry
  end

  def create_billing!(options = {})
    build_billing(options).tap(&:save!)
  end

  def build_billing(options = {})
    return billing if billing.present?

    options[:commission] ||= rentable.owner.try :commission

    super
  end

  def rentable_type
    rentable.class
  end
end
