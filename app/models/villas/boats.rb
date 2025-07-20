module Villas::Boats
  extend ActiveSupport::Concern

  included do
    # TODO: in :mandatory_boat umbenennen
    has_one :inclusive_boat, dependent: :nullify, class_name: "Boat"

    has_and_belongs_to_many :optional_boats, class_name: "Boat"

    # Häuser mit optionalen Booten haben kein exklusiv zugeordnetes
    scope :with_optional_boats, -> {
      left_outer_joins(:inclusive_boat).where(boats: { id: nil })
    }
  end

  def boats
    optional_boats.active.to_a.push(inclusive_boat).compact
  end

  def boat_inclusion
    state = if boat_inclusive?
      "inclusive"
    elsif boat_optional?
      "optional"
    else
      "none"
    end
    ActiveSupport::StringInquirer.new(state)
  end

  def boat_possible?
    boat_inclusive? || boat_optional?
  end

  def boat_optional?
    optional_boats.present?
  end

  def boat_inclusive?
    inclusive_boat.present?
  end
end
