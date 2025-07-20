class Clearing
  class Villa < Clearing::Rentable
    def update(villa_params, inquiry)
      villa_params.prices_valid_at = inquiry.created_at
      Currency.with(inquiry.currency) do
        update_clearing_items Villa::Builder.new(villa_params, inquiry:).build
      end
    end

    def rents
      items = clearing_items.select { |ci|
        ClearingItem::TRAVELER_CATEGORIES.any? do |cat|
          ci.category.include? cat.to_s
        end
      }

      items.sort_by { [_1.start_date, _1.category] }
    end

    def cleaning
      clearing_items.find { _1.category == "cleaning" }&.total
    end

    def pet_fee
      clearing_items.find { _1.category == "pet_fee" }&.total
    end

    def early_checkin
      clearing_items.find { _1.category == "early_checkin" }&.total
    end

    def late_checkout
      clearing_items.find { _1.category == "late_checkout" }&.total
    end

    def to_key
      :villa
    end

    # Rabatte, die auf den Mietpreis angerechnet werden und sich daher auf
    # die Kommission auswirken. siehe intervillas/support#228
    def regular_house_discounts
      discounts.reject { _1.category.include? "repeater" }
    end

    def total_regular_house_discount
      regular_house_discounts.sum(&:total)
    end

    def repeater_discount
      discounts.select { |ci| ci.category.include? "repeater" }.sum(&:total)
    end

    def single_rate_at(night, category:)
      clearing_items.find { |ci|
        ci.category == category &&
          night.evening >= ci.start_date && night.evening < ci.end_date
      }&.price
    end
  end
end
