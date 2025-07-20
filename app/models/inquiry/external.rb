module Inquiry::External
  extend ActiveSupport::Concern

  included do
    after_create :book!, if: :external
  end

  def book!
    create_booking! if booking.blank?
    # bei Nutzung der Booking-Factory mit dem :external-Trait ist das Booking
    # bereits vorhanden
  end
end
