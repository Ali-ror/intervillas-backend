module Inquiry::Reservation
  extend ActiveSupport::Concern

  included do
    has_one :reservation, class_name: "::Reservation"
  end

  def reservation_or_booking
    reservation || booking
  end

  def build_booking_or_reservation(user = nil)
    if immediate_payment_required?(user&.admin?)
      reservation || build_reservation
    else
      build_booking
    end
  end

  def immediate_payment_required?(bypass = false)
    return false if bypass

    currency == Currency::USD && start_date < 40.days.from_now
  end
end
