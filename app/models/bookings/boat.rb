module Bookings::Boat
  extend ActiveSupport::Concern

  included do
    has_one :boat_inquiry, through: :inquiry
    has_one :boat, through: :boat_inquiry

    delegate :boat_possible?, to: :villa
    delegate :with_boat?, :with_villa?, to: :inquiry
  end

  def boat_optional?
    villa.boat_optional?
  end

  def boat_state
    boat_inquiry.try(:boat_state) || 'none'
  end

  def include_boat?
    boat_inquiry.present? && !boat_inquiry.boat_external?
    # return false unless boat_inquiry.present?

    # boat_inquiry.boat_state.free? || (boat_inquiry.boat_state.charged? && !boat_inquiry.boat_external?)
  end

  def boat_name
    boat_inquiry.try(:boat_name)
  end

end
