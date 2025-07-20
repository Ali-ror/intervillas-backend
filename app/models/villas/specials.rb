module Villas::Specials
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :specials
  end

  # @param booking [Booking|DiscountFinder]
  def find_special_for_booking(booking)
    s = specials.where "start_date < :end_date AND end_date > :start_date",
      start_date: booking.start_date,
      end_date:   booking.end_date

    s = s.where("updated_at < ?", booking.created_at) if booking.created_at.present?
    s.first
  end

  def teaser_special_price(special)
    regular_price = villa_price.calculate_base_rate(occupancy: minimum_people, category: :adults) * 7
    # special.discount(regular_price)
  end

  def current_special
    special_for Date.current
  end

  def current_special?
    special_for? Date.current
  end

  def special_for(date = nil)
    @special_for       ||= {}
    @special_for[date] ||= begin
      special = specials.current(date).includes(:villas).references(:villas).first
      # verfügbarkeit prüfen
      special if special&.villas && special.villas.available.include?(self)
    end
  end

  def special_for?(date = nil)
    !!special_for(date)
  end
end
