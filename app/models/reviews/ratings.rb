module Reviews::Ratings
  extend ActiveSupport::Concern

  # Bewerungsbereich (min..max)
  RATING_RANGE = 1..5

  included do
    validates_numericality_of :rating,
      greater_than_or_equal_to: RATING_RANGE.begin,
      less_than_or_equal_to:    RATING_RANGE.end,
      allow_nil:                true
  end

end
