module MyBookingPal
  class LengthOfStay
    # Helper class for LenghOfStay.
    # @private
    class ImportantDates
      DATES = %i[
        start_date
        end_date
        earliest_arrival
        latest_arrival
        latest_departure
        max_compute_date
      ].freeze

      attr_reader(*DATES)

      # Computes some parameters for the LoS price calculation.
      #
      # @param [#to_date] start_date
      #   Begin date of computation
      # @param [#to_date] end_date
      #   Latest arrival date
      # @param [ActiveSupport::Duration] lead_time
      #   Used to compute earliest arrival date
      # @param [ActiveSupport::Duration] compute_limit
      #   Added to start_date in order to compute iteration end. The
      #   actual iteration end may be shifted to the latest departure
      #   date (whichever is farther in the future).
      # @yieldparam [Date] latest_arrival
      #   Last possible arrival date. Used to compute the last possible
      #   departure date.
      # @yieldreturn [ActiveSupport::Duration]
      #   The minimum booking days on the last possible arrival date.
      def initialize(start_date, end_date, lead_time, compute_limit)
        @start_date       = start_date.to_date
        @end_date         = end_date.to_date
        @earliest_arrival = (@start_date + lead_time).to_date
        @latest_arrival   = @end_date
        @latest_departure = (@end_date + yield(latest_arrival)).to_date
        @max_compute_date = [latest_departure, @start_date + compute_limit].max.to_date
      end

      def to_h
        DATES.to_h { [_1, public_send(_1)] }
      end

      def collect_rates
        (start_date..max_compute_date).inject([]) do |list, date|
          list + yield(date)
        end
      end
    end
  end
end
