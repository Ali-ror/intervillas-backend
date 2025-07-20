class Clearing
  class Villa < Rentable
    class Builder < Clearing::Builder # rubocop:disable Metrics/ClassLength
      delegates = delegate :villa, :travelers, :prices_valid_at,
        to: :params
      private(*delegates)

      delegate :villa_price, to: :villa
      private :villa_price

      def build
        build_rents
        build_utilities

        clearing_items
      end

      def legacy_price_structure?
        # Das alte Preismodell wird angewendet, wenn diese bei einer Bestandsbuchung
        # auch noch angewendet wurde.
        return true if inquiry&.clearing_items.present? && inquiry.clearing_items.any? { |ci| ci.category == "adults" }

        false
      end

      def build_rents # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # Für jede Übernachtung muss die Belegung festgestellt werden, da sich die
        # (alten) Preise hiernach richten. TODO: kann eventuell vereinfacht werden,
        # wenn alle Bestandsbuchungen nach altem Preismodell abgerechnet sind.
        #
        # Es gibt seit support#563 noch einen weiteren Sonderfall, bei dem das Haus
        # "wochenweise" (unabhängig von der Anzahl der Personen) berechnet wird. Dies
        # ist der Fall, wenn villa_price.weekly_priced? wahr ist.

        travelers_by_category_and_night.each do |category, night_collection|
          night_collection.each do |(nights, single_rate), travelers|
            next if travelers.blank?

            travelers_start_date = nights.min.evening
            travelers_end_date   = nights.max.morning

            build_rent_clearing_item(category, single_rate, travelers.size, travelers_end_date, travelers_start_date)

            # Discounts
            #
            # Für einen Zeitabschnitt die gültigen Discounts finden und Item bauen
            discounts = if inquiry&.persisted?
              inquiry.discounts.where(inquiry_kind: "villa")
            else
              DiscountFinder.new(villa, travelers_start_date, travelers_end_date, Time.current)
            end

            discounts.each do |discount|
              # Überspringen, wenn Discount-Range ausserhalb Reisezeitraum.
              # Tritt auf, wenn einzelne Traveler später an- oder früher abreisen.
              next if discount.period.min > travelers_end_date || discount.period.max < travelers_start_date

              discount_start = [discount.period.min, travelers_start_date].max
              discount_end   = [discount.period.max, travelers_end_date].min

              next if discount_start == discount_end # Posten mit Länge 0 ignorieren

              build_discount_clearing_item(category, discount, discount_end, discount_start, single_rate, travelers.size) # rubocop:disable Layout/LineLength
            end
          end
        end
      end

      def build_utilities
        %i[deposit cleaning].each do |utility|
          price = find_utility_price \
            category: utility

          build_clearing_item \
            category:     utility,
            price:        price,
            normal_price: price.normal_price
        end
      end

      private

      def build_discount_clearing_item(category, discount, discount_end, discount_start, single_rate, travelers_count) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        if legacy_price_structure? || category != "adults"
          return if villa_price.weekly_pricing? # avoid items with value == 0

          discount_category = discount_category(category, discount)
          booked_rate       = booked_rate_at(Night.new(discount_start), category: discount_category)

          return build_clearing_item(
            category:     discount_category,
            price:        booked_rate || discount.absolutize(single_rate),
            normal_price: single_rate.normal_price && discount.absolutize(single_rate.normal_price),
            amount:       travelers_count,
            start_date:   discount_start,
            end_date:     discount_end,
          )
        end

        discount_category  = discount_category(:base_rate, discount)
        clearing_normal    = discount.absolutize(rate_from_clearing(:base_rate))
        rate_from_clearing = rate_from_clearing(discount_category, normal_price: clearing_normal)

        build_clearing_item(
          category:     discount_category,
          price:        rate_from_clearing,
          normal_price: rate_from_clearing.normal_price,
          amount:       1, # Grundpreis umfasst 2 Erwachsene
          start_date:   discount_start,
          end_date:     discount_end,
        )

        return unless travelers_count > villa.minimum_people
        return if     villa_price.weekly_pricing? # avoid items with value == 0

        discount_category  = discount_category(:additional_adult, discount)
        clearing_normal    = discount.absolutize(rate_from_clearing(:additional_adult))
        rate_from_clearing = rate_from_clearing(discount_category, normal_price: clearing_normal)

        build_clearing_item(
          category:     discount_category,
          price:        rate_from_clearing,
          normal_price: rate_from_clearing.normal_price,
          amount:       travelers_count - villa.minimum_people,
          start_date:   discount_start,
          end_date:     discount_end,
        )
      end

      # Bei neuer Preisstruktur müssen 2 Erwachsene Reisende zum Grundpreis
      # zusammengefasst werden. Sind darüber hinaus noch Erwachsene Reisende
      # vorhanden, werden diese als "additional_adult" berechnet.
      def build_rent_clearing_item(category, single_rate, travelers_count, travelers_end_date, travelers_start_date)
        if legacy_price_structure? || category != "adults"
          return if villa_price.weekly_pricing? # avoid items with value == 0

          return build_clearing_item(
            category:     category,
            price:        single_rate,
            normal_price: single_rate.normal_price,
            amount:       travelers_count,
            start_date:   travelers_start_date,
            end_date:     travelers_end_date,
          )
        end

        price = rate_from_clearing(:base_rate)
        build_clearing_item(
          category:     (villa_price.weekly_pricing? ? :weekly_rate : :base_rate),
          price:        price,
          normal_price: price.normal_price,
          amount:       1, # Grundpreis umfasst 2 Erwachsene
          start_date:   travelers_start_date,
          end_date:     travelers_end_date,
        )

        return unless travelers_count > villa.minimum_people
        return if     villa_price.weekly_pricing?  # avoid items with value == 0

        price = rate_from_clearing(:additional_adult)
        build_clearing_item(
          category:     :additional_adult,
          price:        price,
          normal_price: price.normal_price,
          amount:       travelers_count - villa.minimum_people,
          start_date:   travelers_start_date,
          end_date:     travelers_end_date,
        )
      end

      # zunächst nach Kategorie (Erw., Kind bis 12, Kind bis 6) gruppieren,
      # dann nach Übernachtungszeitraum.
      #
      # Der Übernachtungszeitraum wird als Clearing::Villa::NightCollection dargestellt.
      #
      # @return [Hash{String->Clearing::Villa::NightCollection}]
      def travelers_by_category_and_night
        travelers.group_by(&:price_category).each_with_object({}) do |(category, travelers), group|
          nights.each do |night|
            # Tage mit identischer Belegung und Preis(siehe #262)
            # innerhalb einer Kategorie können zusammengefasst werden
            staying_travelers = travelers.select { |t| t.stays_over?(night) }

            price = find_price \
              night:     night,
              occupancy: staying_travelers.size,
              category:  category,
              valid_at:  prices_valid_at

            group[category] ||= NightCollection.new
            group[category].add night, staying_travelers, price
          end
        end
      end

      def discount_category(category, discount)
        [category, discount.subject].join("_")
      end

      def booked_rate_at(night, category:)
        return unless inquiry

        inquiry.clearing.villa_clearing.single_rate_at(night, category: category)
      end

      # @param [String] category
      # @param [Currency::Value] normal_price Optional kann der Normalpreis übergeben werden,
      #   wenn dieser sich nicht über VillaPrice ermitteln lässt. z.B. für Discounts
      def rate_from_clearing(category = "base_rate", normal_price: nil)
        rate           = inquiry&.clearing_items&.where(category: category)&.first&.price
        normal_price ||= unfee_external_usd_booking(villa_price.public_send(category))

        SingleRate.new(rate || normal_price, normal_price: normal_price)
      end

      def find_price(night:, occupancy:, category:, **)
        return SingleRate.new(0) if occupancy.zero?

        normal_price = villa_price.calculate_base_rate(
          occupancy: occupancy,
          category:  category,
        ) / occupancy

        normal_price = unfee_external_usd_booking(normal_price)
        single_rate  = (booked_rate_at(night, category: category) if inquiry&.clearing_items.present?)

        SingleRate.new single_rate || normal_price,
          normal_price: normal_price
      end

      def find_utility_price(category:)
        item = inquiry&.clearing_items&.find { |it|
          it.category == category.to_s && it.villa_id?
        }

        normal_price = unfee_external_usd_booking(villa_price.public_send(category))

        SingleRate.new item&.price || normal_price,
          normal_price: normal_price
      end

      def start_date
        travelers.min_by(&:start_date).start_date
      end

      def end_date
        travelers.max_by(&:end_date).end_date
      end

      # @return [Array<Clearing::Villa::Night>] Übernachtungen
      def nights
        (start_date...end_date).to_a.map { |d| Night.new(d) }
      end

      def build_clearing_item(**attributes)
        attrs = attributes.merge(villa_id: villa.id, inquiry_id: inquiry&.id)

        if (cat = attrs[:category].to_s).present? && (cat.start_with?("base_rate") || cat == "adults")
          attrs[:minimum_people] = villa.minimum_people
        end

        clearing_items << ClearingItem.new(**attrs)
      end

      # Externe Buchungen in USD dürfen die KK-Gebühr nicht enthalten,
      # siehe Issue: support#648
      def unfee_external_usd_booking(amount)
        return amount unless external && villa_price.target_currency == Currency::USD

        Currency::Value.new(amount.unceiled / cc_factor, Currency::USD)
      end

      def cc_factor
        @cc_factor ||= 1 + (::Setting.cc_fee_usd / 100)
      end
    end
  end
end
