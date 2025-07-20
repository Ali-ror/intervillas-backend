module Villas::PropertyLocations
  extend ActiveSupport::Concern

  CARDINAL_DIRECTIONS = %w[n ne e se s sw w nw].freeze

  included do
    validates :pool_orientation,
      presence:  false,
      inclusion: { in: CARDINAL_DIRECTIONS, allow_nil: true }
  end
end
