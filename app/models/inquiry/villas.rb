module Inquiry::Villas
  extend ActiveSupport::Concern

  included do
    has_one :villa_inquiry
    has_one :villa,
      through: :villa_inquiry

    delegate :start_date, :end_date,
      to: :rentable_inquiry

    delegate :adults, :children_under_6, :children_under_12,
      to: :villa_inquiry

    accepts_nested_attributes_for :villa_inquiry,
      update_only: true
  end

  def rentable_inquiry
    villa_inquiry || boat_inquiry
  end

  def boat_possible?
    villa.present? && villa.boat_possible?
  end

  def traveler_price_categories
    villa_inquiry&.villa&.traveler_price_categories_for_currency(currency)
  end
end
