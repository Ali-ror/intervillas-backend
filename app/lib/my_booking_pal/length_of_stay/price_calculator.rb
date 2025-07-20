module MyBookingPal
  class LengthOfStay
    class PriceCalculator
      # @return [VillaPrice::MonetaryWrapper] Villa prices in USD.
      attr_reader :prices

      # Any High Season which may affect the prices, might be empty.
      attr_reader :high_seasons

      # holiday surcharges, might be nil.
      attr_reader :easter_discount, :xmas_discount

      # surcharge to counteract channel commission
      attr_reader :commission_surcharge

      def initialize(villa:, commission_surcharge:)
        @prices               = villa.villa_price(Currency::USD)
        @high_seasons         = villa.high_seasons
        discounts             = villa.holiday_discounts
        @easter_discount      = discounts.find { |el| el.description == "easter" }
        @xmas_discount        = discounts.find { |el| el.description == "christmas" }
        @commission_surcharge = commission_surcharge
      end

      # Computes the total surcharge factor from holiday/high season surcharges.
      # This needs to be multiplied by the people price ("base rate").
      def surcharges_on(date)
        @surcharges_on ||= Hash.new { |h, key|
          h[key] = individual_surcharges_on(key).values.reduce(1.to_d) { |prod, pct|
            prod * percentage_to_factor(pct)
          }
        }

        @surcharges_on[date]
      end

      # Collects the various surcharges affecting the base rate. This is useful
      # information to retreive the base rate from an already processed total
      # (i.e. when creating a local booking from a BookingPal reservation).
      #
      # @return [Hash<Symbol, BigDecimal>]
      def individual_surcharges_on(date)
        @individual_surcharges_on ||= Hash.new { |h, key|
          h[key] = {
            easter:      easter_surcharge(key),      # >= 0
            xmas:        xmas_surcharge(key),        # >= 0
            high_season: high_season_surcharge(key), # >= 0
            commission:  commission_surcharge,       # >= 0
          }
        }

        @individual_surcharges_on[date]
      end

      # Computes rates for each date from `date` til `date + max_offset.days`.
      #
      # By convention, dates before `date + min_offset.days` are priced at 0,
      # meaning "unavailable". The other dates represent the average daily price.
      def compute_rates(date, min_offset, max_offset, num_adults)
        base_rate = prices.calculate_base_rate(occupancy: num_adults)

        # Array<rates for each day, cumulative sum>
        day_rates = 1.upto(max_offset).map { |offset|
          base_rate * surcharges_on(date + offset.days)
        }

        # cumulative average daily prices. dates < `date + min_offset.days`
        # are zero'ed by convention
        rates = day_rates.map.with_index { |_, i|
          next 0 if i + 1 < min_offset # unavailable

          day_rates[0..i].sum(0).to_f.round(2)
        }

        # Trim trailing zeros (Enum#drop_while removes leading entries).
        #
        # XXX: In most cases, this replaces `rates` with an empty array because all
        # values are zero (i.e. min_offset >= max_offset). Need to find out, whether
        # there's ever a counter example to this.
        rates.pop while rates.size > 0 && rates[-1].zero?

        rates
      end

      private

      ZERO = 0.to_d
      private_constant :ZERO

      def percentage_to_factor(percent)
        (100.to_d + percent) / 100
      end

      class NoCover
        def cover?(*)
          false
        end
      end
      private_constant :NoCover

      def range_for(discount, &block)
        return Hash.new(NoCover.new) if discount.nil?

        Hash.new { |h, y|
          h[y] = block.call(y, discount.days_before, discount.days_after)
        }
      end

      def easter_range
        @easter_range ||= range_for(easter_discount) { |year, n_before, n_after|
          easter       = Date.easter(year)
          easter_start = easter - n_before
          easter_end   = easter + n_after

          (easter_start..easter_end)
        }
      end

      def easter_surcharge(date)
        return ZERO unless easter_range[date.year].cover?(date)

        easter_discount.percent.to_d
      end

      def xmas_range
        @xmas_range ||= range_for(xmas_discount) { |year, n_before, n_after|
          xmas_start = Date.new(year, 12, 25) - n_before
          xmas_end   = Date.new(year, 12, 26) + n_after

          (xmas_start..xmas_end)
        }
      end

      def xmas_surcharge(date)
        return ZERO unless xmas_range[date.year].cover?(date)

        xmas_discount.percent.to_d
      end

      def high_season_surcharge(date)
        high_seasons.sum(ZERO) { _1.cover?(date) ? _1.addition : ZERO }
      end
    end
  end
end
