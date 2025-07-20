module Villas::Reviews
  extend ActiveSupport::Concern

  # ab wie vielen freigeschalteten Reviews sollen diese auch angezeigt werden?
  MIN_PUBLISHED_REVIEWS = 1

  included do
    has_many :reviews, -> { undeleted.published }

    # wird nur für Kunden gebraucht, die auf die Review-Mail reagieren;
    # die müssen nicht wissen, dass das Review "gelöscht" wurde
    has_many :unpublished_reviews, -> { unpublished },
      class_name: "Review"
  end

  # durchschnittliche Bewertung (auf eine Nachkommastelle)
  def avg_rating
    reviews.average(:rating).round(1)
  end

  # Anzahl Bewertungen
  def number_of_ratings
    reviews.count
  end

  def show_reviews?
    number_of_ratings >= MIN_PUBLISHED_REVIEWS
  end

  # Anzahl ganzer und halber Sterne
  def stars(reload = false)
    @stars   = nil if reload
    @stars ||= begin
      reviews.reload

      # when avg == 4.2 then full, decimals = 4, 0.2
      full, decimals = avg_rating.divmod 1
      full           = full.to_i

      if decimals < 0.25
        [full, 0] # round down (no half star)
      elsif decimals > 0.75
        [full + 1, 0] # round up (extra full star, no half star)
      else
        [full, 1] # 0.25..0.75 = 1 half start
      end
    end
  end
end
