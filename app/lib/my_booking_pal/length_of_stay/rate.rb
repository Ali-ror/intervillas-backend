module MyBookingPal
  class LengthOfStay
    Rate = Struct.new(:date, :num_adults, :rates, :category) do
      def self.from_remote(data)
        date   = data["checkInDate"].to_date
        guests = data["maxGuests"]

        rates = data.fetch("losValue", [])
        rates.pop while rates[-1]&.zero?

        new(date, guests, rates, nil)
      end

      def initialize(date, num_adults, rates, category)
        super date, num_adults, rates.map { normalize_rate(_1) }, category
      end

      def as_json(*)
        # Edge case: To delete a date/num_adults combination, we must submit
        # at least one zero value, otherwise this entry will be ignored...
        val = rates.empty? ? [0] : rates

        {
          checkInDate: date.strftime("%Y-%m-%d"),
          maxGuests:   num_adults,
          losValue:    val,
        }
      end

      private

      # chose Integer representation
      def normalize_rate(val)
        return val if val.is_a?(Integer)

        rat = val.to_r.truncate(3)
        rat.denominator == 1 ? rat.to_i : val
      end
    end
  end
end
