module Inquiry::Booking
  extend ActiveSupport::Concern

  included do
    has_one :booking, class_name: "::Booking"
  end

  def booked_at
    booking&.created_at
  end

  def booking_updated_at
    booking&.updated_at
  end

  def booked?
    !cancelled? && booking.present?
  end

  def for_corporate?
    external? || start_date >= Rails.configuration.x.corporate_switch_date
  end
end
