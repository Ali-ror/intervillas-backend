require "clearing/rentable"

class Clearing
  class Boat < Rentable
    def update(boat_params, inquiry)
      boat_params.prices_valid_at = inquiry.created_at
      update_clearing_items Boat::Builder.new(boat_params, inquiry).build
    end

    def rents
      @rents ||= clearing_items
        .select { |ci| ci.category.include? "price" }
        .sort_by(&:category)
    end

    def training
      find_clearing_item("training")&.total
    end

    def to_key
      :boat
    end

    def single_rate
      find_clearing_item("price")&.price
    end

    private

    def find_clearing_item(category)
      clearing_items.find { |ci| ci.category == category }
    end
  end
end
