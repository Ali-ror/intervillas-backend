# == Schema Information
#
# Table name: holiday_discounts
#
#  boat_id     :integer
#  created_at  :datetime         not null
#  days_after  :integer          not null
#  days_before :integer          not null
#  description :string           not null
#  id          :integer          not null, primary key
#  percent     :integer          not null
#  updated_at  :datetime         not null
#  villa_id    :integer
#
# Indexes
#
#  fk__holiday_discounts_boat_id   (boat_id)
#  fk__holiday_discounts_villa_id  (villa_id)
#
# Foreign Keys
#
#  fk_holiday_discounts_boat_id   (boat_id => boats.id)
#  fk_holiday_discounts_villa_id  (villa_id => villas.id)
#

class HolidayDiscount < ApplicationRecord
  belongs_to :villa, optional: true # optional, weil NULL erlaubt
  belongs_to :boat, optional: true # optional, weil NULL erlaubt

  validates :percent, :days_after, :days_before, :description,
    presence: true

  validates :percent, numericality: {
    only_integer:             true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to:    100,
  }

  validates :days_before, numericality: {
    only_integer:             true,
    greater_than_or_equal_to: 1,
  }

  validates :days_after, numericality: {
    only_integer:             true,
    greater_than_or_equal_to: 1,
  }

  scope :easter, -> { where description: "easter" }
  scope :christmas, -> { where description: "christmas" }

  def christmas? = description == "christmas"
  def easter?    = description == "easter"

  def self.discount_days(dateable)
    all.to_a.sum(DiscountDays.new) { |discount|
      DiscountDays.build(discount, dateable)
    }
  end

  # Die Vorjahres-Discounts müssen beachtet werden, weil der Weihnachtsaufschlag
  # i.d.R. noch recht weit in den Januar hereinragt. Die Discounts des Folgejahres
  # müssen beachtet werden, da es auch Buchungen geben kann, die von Weihnachten
  # bis Ostern gehen.
  #
  # Siehe https://git.digineo.de/intervillas/support/issues/185
  def date_ranges(year)
    [year - 1, year, year + 1].map do |discount_year|
      if christmas?
        min_limit = Date.parse("#{discount_year}-12-25") - days_before
        max_limit = Date.parse("#{discount_year}-12-26") + days_after

        min_limit..max_limit
      elsif easter?
        easter    = Date.easter(discount_year)
        min_limit = easter - days_before
        max_limit = easter + days_after

        min_limit..max_limit
      end
    end
  end

  def price(undiscounted_price_for_single_night)
    undiscounted_price_for_single_night * (100.0 + percent) / 100.0
  end
end
