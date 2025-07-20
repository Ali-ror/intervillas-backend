class Clearing
  class VillaParams
    def self.from_villa_inquiry(villa_inquiry)
      villa_params       = new
      villa_params.villa = villa_inquiry.villa

      if villa_inquiry.travelers.present?
        villa_params.travelers = villa_inquiry.travelers
      else
        villa_params.start_date        = villa_inquiry.start_date
        villa_params.end_date          = villa_inquiry.end_date
        villa_params.adults            = villa_inquiry.adults
        villa_params.children_under_6  = villa_inquiry.children_under_6
        villa_params.children_under_12 = villa_inquiry.children_under_12
      end

      villa_params.prices_valid_at = villa_inquiry.created_at
      villa_params
    end

    attr_accessor :villa, :travelers, :prices_valid_at

    delegate :boat_inclusive?, to: :villa

    def initialize
      self.travelers       = []
      self.prices_valid_at = Time.current
      self.start_date      = Date.current
    end

    def adults=(adults_count)
      adults_count.to_i.times { travelers << build_traveler(price_category: "adults") }
    end

    def children_under_12=(children_under_12_count)
      children_under_12_count.to_i.times { travelers << build_traveler(price_category: "children_under_12") }
    end

    def children_under_6=(children_under_6_count)
      children_under_6_count.to_i.times { travelers << build_traveler(price_category: "children_under_6") }
    end

    def start_date
      @start_date ||= travelers.min_by(&:start_date)&.start_date
    end

    def start_date=(in_start_date)
      @start_date = in_start_date
      travelers.each do |t|
        t.start_date = in_start_date
      end
    end

    def end_date=(in_end_date)
      @end_date = in_end_date

      travelers.each { |t| t.end_date = in_end_date }
    end

    def end_date
      @end_date ||= travelers.max_by(&:end_date)&.end_date
    end

    def valid?
      villa.present? &&
        start_date.present? &&
        end_date.present? &&
        travelers.present?
    end

    def boat_params
      BoatParams.new.tap do |bp|
        bp.boat       = villa.inclusive_boat
        bp.start_date = start_date.to_date + 1.day
        bp.end_date   = end_date.to_date - 1.day
      end
    end

    private

    def build_traveler(params)
      Traveler.new(params.merge(start_date: start_date, end_date: end_date))
    end
  end
end
