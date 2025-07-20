module BoatInquiry::Clearing
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_clearing_items

    before_create :create_clearing_items

    delegate :booked?,
      to: :inquiry

    has_many :clearing_items, foreign_key: %i[inquiry_id boat_id], dependent: :destroy
  end

  def clearing
    @clearing ||= Clearing::Boat.new(clearing_items)
  end

  # initiale Abrechnungs-Posten erstellen
  def create_clearing_items
    self.boat_state = if boat.inclusive?
      "free"
    else
      "charged"
    end

    return true if skip_clearing_items

    clearing_builder.save_to(inquiry)
    clearing_items.reload
  end

  def clearing_builder
    boat_params = ::Clearing::BoatParams.new.tap do |bp|
      bp.boat            = boat
      bp.start_date      = start_date
      bp.end_date        = end_date
      bp.prices_valid_at = created_at
    end
    Clearing::Boat::Builder.new(boat_params, inquiry).tap(&:build)
  end

  delegate :charged?, to: :boat_state
end
