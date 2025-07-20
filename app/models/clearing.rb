# Eine (fiktive) Abrechnung
#
class Clearing
  attr_accessor :rentable_clearings, :clearing_items

  def initialize(rentable_clearings, clearing_items = [])
    self.rentable_clearings = rentable_clearings
    self.clearing_items     = clearing_items
  end

  # Aktualisiert das Clearing mit neuen Parametern
  # Die Änderungen sind nicht persistent, sondern werden nur zum Aktualisieren
  # der PriceTable.vue genutzt. Durch das Speichern im EditorCommon.js können
  # die hier erzeugten ClearingItems dann gespeichert werden.
  def update(villa_params, boat_params, inquiry) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    rentable_clearings.each do |rc|
      if rc.is_a?(Villa)
        rc.update(villa_params, inquiry) if villa_params.present?
      elsif rc.is_a?(Boat)
        rc.update(boat_params, inquiry)
      end
    end

    if rentable_clearings.none? { |rc| rc.is_a?(Boat) } && boat_params.present?
      boat_params.prices_valid_at = Time.current
      rentable_clearings << Clearing::Boat::Builder.new(boat_params, inquiry).build_clearing
    end

    self
  end

  class BoatParams
    attr_accessor :boat, :start_date, :end_date, :prices_valid_at
  end

  def self.build(villa_params, external: false)
    rentable_clearings = []

    builder = Clearing::Villa::Builder.new(villa_params, external: external)
    rentable_clearings << Clearing::Villa.new(builder.build)

    if villa_params.boat_inclusive?
      builder = Clearing::Boat::Builder.new(villa_params.boat_params, nil)
      rentable_clearings << Clearing::Boat.new(builder.build)
    end

    new rentable_clearings
  end

  def for_rentable(rentable_sym)
    rentable_clearings.find { |rc| rc.rentable_sym == rentable_sym }
  end

  def sub_total
    (rents + other_clearing_items).sum(&:total)
  end

  def total
    all_clearing_items.sum(&:total)
  end

  def discounts
    rentable_clearings.flat_map(&:discounts)
  end

  def discount_note
    discounts.map(&:note).join " / "
  end

  def reversals
    rentable_clearings.flat_map(&:reversals)
  end

  def deposits
    rentable_clearings.flat_map(&:deposits)
  end

  include Clearing::CommonTotals

  def villa_clearing
    rentable_clearings.find { |c| c.is_a? Villa }
  end

  delegate :total_regular_house_discount, to: :villa_clearing

  def utilities
    rentable_clearings.flat_map(&:utilities)
  end

  def other_clearing_items
    utilities + clearing_items
  end

  def start_date
    all_clearing_items.select(&:start_date).min_by(&:start_date).start_date
  end

  def end_date
    all_clearing_items.select(&:end_date).max_by(&:end_date).end_date
  end

  def nights
    (start_date...end_date).count
  end

  def days
    nights + 1
  end

  def all_clearing_items
    clearing_items + rentable_clearings.flat_map(&:clearing_items)
  end

  def rents
    rentable_clearings.flat_map(&:rents)
  end

  def as_json(*)
    json = ApplicationController.render(
      partial: "api/clearings/clearing",
      locals:  { clearing: self, inquiry: inquiry },
      format:  :json,
    )
    JSON.parse(json)
  end
end
