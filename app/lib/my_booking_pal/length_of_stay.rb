module MyBookingPal
  class LengthOfStay
    attr_reader :product, :lead_time, :compute_limit
    attr_reader :max_stay, :advance_months, :surcharge

    delegate :villa,
      to: :product

    delegate :villa_inquiries,
      to: :villa

    # Lead time, i.e. the earliest date (relative from Date.current) a
    # reservervation will be accepted.
    DEFAULT_LEAD_TIME = 2.days

    # Absolute last day to precompute rates for in #compute_rates. This is
    # needed to clear out stale prices on the remote server, in case
    # `advance_months` in Villa#additional_properties is reduced.
    DEFAULT_COMPUTE_LIMIT = 24.months

    # A Stay is a simplified date range.
    #
    # We don't use an actual Range here, because of its implementation of #cover?,
    # which always includes the start date, however we need to have both start and
    # end date to be excluded.
    Stay = Struct.new(:start_date, :end_date) do
      def cover?(date)
        start_date < date && date < end_date
      end
    end

    def initialize(product, lead_time: DEFAULT_LEAD_TIME, compute_limit: DEFAULT_COMPUTE_LIMIT)
      @product       = product
      @lead_time     = lead_time
      @compute_limit = compute_limit

      props           = villa.additional_properties_with_defaults.fetch(:los)
      @max_stay       = props.fetch(:max_stay)
      @advance_months = props.fetch(:advance_months)
      @surcharge      = props.fetch(:surcharge, 0)
    end

    def compute_rates(start_date: Date.current, end_date: (start_date + advance_months.months))
      dates = ImportantDates.new(start_date, end_date, lead_time, compute_limit) { |latest_arrival|
        nights_calculator.for(latest_arrival, nil).days
      }

      occupied = lookup_occupancies(dates.earliest_arrival, dates.latest_departure)

      dates.collect_rates do |date|
        daily_rates(date, dates.earliest_arrival, dates.latest_departure, occupied)
      end
    end

    private

    def nights_calculator
      @nights_calculator ||= MinimumNightsHelper.new(villa: villa)
    end

    def price_calculator
      @price_calculator ||= PriceCalculator.new(villa: villa, commission_surcharge: surcharge)
    end

    def daily_rates(date, earliest_arrival, latest_departure, occupied)
      return daily_people_rates(date, :early) if date < earliest_arrival
      return daily_people_rates(date, :late)  if date > latest_departure

      currently_occupied, stay = find_next_stay(date, occupied)
      return daily_people_rates(date, :occupied) if currently_occupied

      # TODO: This ignores gaps shorter than min days.
      # We can't use Booking.gap_after here.
      min = nights_calculator.for(date, stay.start_date)
      max = [(stay.start_date - date).to_i, max_stay].min

      daily_people_rates(date, :ok) { |num_people|
        price_calculator.compute_rates(date, min, max, num_people)
      }
    end

    def daily_people_rates(date, category)
      villa.minimum_people.upto(villa.beds_count).map do |n|
        Rate.new(date, n, block_given? ? yield(n) : [], category)
      end
    end

    def lookup_occupancies(start_date, end_date)
      # ensure we can fit a full stay on the last day of the range
      end_date += (max_stay + 1).days

      actual = OccupancyExporter.from(villa)
        .public_export(limit: [start_date, end_date])
        .map { |s, e| Stay.new(s, e) }

      # append a dummy entry, so that #find_next_stay terminates early
      actual << Stay.new(end_date, nil)
    end

    def find_next_stay(date, occupied)
      cmp        = date.to_datetime.change(hour: 12)
      next_index = occupied.find_index { |stay| cmp < stay.start_date }
      return [nil, occupied[-1]] if next_index.nil?

      next_stay     = occupied[next_index]
      curr_occupied = next_index > 0 && occupied[next_index - 1].cover?(cmp)
      [curr_occupied, next_stay]
    end

    MinimumNightsHelper = Struct.new(:villa, keyword_init: true) do
      extend NightsCalculator::ClassMethods

      def for(start_date, end_date)
        self.class.minimum_booking_nights(start_date, end_date, villa: villa)
      end
    end
    private_constant :MinimumNightsHelper
  end
end
