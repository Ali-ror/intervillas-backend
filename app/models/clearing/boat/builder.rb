class Clearing
  class Boat < Rentable
    class Builder < Clearing::Builder
      attr_accessor :boat
      include BoatDaysCalculator

      def initialize(boat_params, inquiry)
        self.boat = boat_params.boat
        super boat_params, inquiry: inquiry
      end

      def build_clearing
        Clearing::Boat.new(build)
      end

      def build
        build_rent
        build_utilities

        clearing_items
      end

      def build_rent # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        return if boat.inclusive? || start_date.blank? || end_date.blank?

        boat_price = find_price(boat_days)
        build_clearing_item \
          category:     :price,
          price:        boat_price,
          normal_price: boat_price.normal_price,
          start_date:   start_date,
          end_date:     end_date

        # Discounts
        #
        # Für einen Zeitabschnitt die gültigen Discounts finden und Item bauen
        discounts = if inquiry&.boat_inquiry&.persisted?
          inquiry.discounts.where(inquiry_kind: "boat")
        else
          DiscountFinder.new(boat, start_date, end_date, Time.current)
        end

        discounts.each do |discount|
          discount_category = ["price", discount.subject].join("_")
          discount_start    = [discount.period.begin, start_date].max
          discount_end      = [discount.period.end, end_date].min

          build_clearing_item \
            category:     discount_category,
            price:        discount.absolutize(boat_price),
            normal_price: boat_price.normal_price && discount.absolutize(boat_price.normal_price),
            start_date:   discount_start,
            end_date:     discount_end
        end
      end

      def build_utilities
        %i[deposit training].each do |utility|
          price = find_utility_price \
            category:     utility,
            normal_price: boat_prices.public_send(utility).value

          build_clearing_item \
            category:     utility,
            price:        price,
            normal_price: price.normal_price
        end
      end

      private

      def find_price(boat_days)
        normal_price = boat_prices.daily_price(boat_days)
        single_rate  = (inquiry.clearing.for_rentable(:boat)&.single_rate if inquiry&.clearing_items.present?)

        SingleRate.new single_rate || normal_price,
          normal_price: normal_price
      end

      def find_utility_price(category:, normal_price:)
        item = inquiry&.clearing_items&.find { |it|
          it.category == category.to_s && it.boat_id?
        }
        return SingleRate.new(normal_price, normal_price: normal_price) unless item

        SingleRate.new(item.price, normal_price: normal_price)
      end

      def start_date
        params.start_date.to_date
      end

      def end_date
        params.end_date.to_date
      end

      def build_clearing_item(**attributes)
        clearing_items << ClearingItem.new(
          **attributes,
          boat_id:    boat.id,
          inquiry_id: inquiry&.id,
        )
      end

      def boat_prices
        @boat_prices ||= begin
          currency = inquiry&.currency || Currency.current
          valid_at = params.prices_valid_at || Time.current

          boat.boat_price(currency, valid_at: valid_at)
        end
      end
    end
  end
end
