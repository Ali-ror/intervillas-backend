module NightsCalculator
  extend ActiveSupport::Concern

  MINIMUM_BOOKING_NIGHTS      = 7
  MINIMUM_BOOKING_NIGHTS_XMAS = 14
  ABSOLUTE_MINIMUM_DAYS       = 3 # 1 night + 2 days arrival/departure

  def minimum_nights
    @minimum_nights ||= villa.try(:gap_after, start_date) ||
      self.class.minimum_booking_nights(start_date, end_date, villa: villa)
  end

  def nights
    return 0 if end_date.blank? || start_date.blank?

    (end_date - start_date).to_i
  end
  alias_method :period, :nights # rubocop:disable Style/Alias:

  def days
    nights + 1
  end

  module ClassMethods
    # In general, villas need to be booked for at least 7 consecutive nights,
    # and 14 nights if the booking touches the christmas holidays. If the booking
    # range touches a special, the minimum may drop to 3 days.
    #
    # Note: Since #653, villas may define an individual minimum.
    #
    # @param [Date] start_date day of arrival
    # @param [Date] end_date day of departure
    # @param [Boolean] special Does the date range touch a special?
    # @param [Villa] villa restrict return value to villa
    # @return [Integer] Number of min. booking nights
    def minimum_booking_nights(start_date = nil, end_date = nil, special: false, villa: nil)
      min = if special
        ABSOLUTE_MINIMUM_DAYS
      elsif villa
        villa.minimum_booking_nights
      else
        MINIMUM_BOOKING_NIGHTS
      end
      return min unless start_date

      end_date  ||= start_date + min
      # Datusmgrenzen mit XmasProvider synchron halten
      # (app/javascript/intervillas-drp/special-dates.js)
      xmas_from   = Date.new start_date.year, 12, 23
      xmas_to     = Date.new start_date.year, 12, 26

      overlaps = (start_date - xmas_to) * (xmas_from - end_date) >= 0
      overlaps ? [MINIMUM_BOOKING_NIGHTS_XMAS, min].max : min
    end
  end
end
