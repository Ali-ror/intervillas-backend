# == Schema Information
#
# Table name: travelers
#
#  born_on        :date
#  created_at     :datetime         not null
#  end_date       :date
#  first_name     :string
#  id             :integer          not null, primary key
#  inquiry_id     :integer          not null
#  last_name      :string
#  price_category :string           default("adults"), not null
#  start_date     :date
#  updated_at     :datetime         not null
#
# Indexes
#
#  fk__travelers_booking_id  (inquiry_id)
#
# Foreign Keys
#
#  fk_rails_...  (inquiry_id => inquiries.id) ON DELETE => cascade
#

class Traveler < ApplicationRecord
  CATEGORIES          = %i[adults children_under_6 children_under_12].freeze
  CATEGORY_TO_MIN_AGE = {
    adults:            13,
    children_under_6:  0,
    children_under_12: 7,
  }.freeze

  belongs_to :inquiry

  # Wenn der Reisezeitraum nicht bereits festgelegt ist, dann wird dieser aus
  # der Buchung übernommen.
  before_validation :take_dates, if: -> { inquiry.present? }, on: :create

  validates :price_category, inclusion: { in: %w[adults children_under_6 children_under_12] }

  validate :age_must_match_price_category

  scope :of_category, ->(category) { where(price_category: category) }

  def age_must_match_price_category
    return unless born_on.present? && price_category.to_s != price_category_by_age.to_s

    errors.add(:born_on, :price_category_missmatch)
  end

  def self.born_on_for_traveler_category(traveler_category, start_date)
    start_date - CATEGORY_TO_MIN_AGE[traveler_category].years
  end

  def name
    "#{first_name} #{last_name}"
  end

  # Altersberechnung nach § 188 Abs. 3
  #
  # Der bisherige Ansatz ((ref - born_on) / 1.year).floor ist nur in erster
  # Näherung korrekt, und in 75% der Fälle falsch, wenn ein Geburtstag als
  # Referenzdatum gegeben ist.
  def age(ref = Date.current)
    return unless born_on?

    # split dates into parts
    ry = ref.year
    rm = ref.month
    rd = ref.day
    by = born_on.year
    bm = born_on.month
    bd = born_on.day

    # age = diff(years) - (1 if day-of-year(ref) < day-of-year(born_on))
    (ry - by) - (rm < bm || (rm == bm && rd < bd) ? 1 : 0)
  end

  def birthday?(ref = Date.current)
    rm = ref.month
    rd = ref.day
    bm = born_on.month
    bd = born_on.day
    return rd == 1 && rm == 3 if !ref.leap? && bd == 29 && bm == 2

    bd == rd && bm == rm
  end

  # Kinder, die am Anreisetag 6 oder 12 werden, zählen noch in die unter 6/
  # unter 12 Kategorie (Kundenbindung/Sympathiepunkte, siehe support#249)
  #
  # Spezial-Behandlung für Kinder, die am 29.02. Geburtstag haben:
  #
  #   In Nichtschaltjahren gilt nach § 188 Abs. 3 BGB die Vollendung des
  #   28. Februar als Ablauftag, sie stehen daher in Nichtschaltjahren den
  #   an einem 1. März Geborenen gleich.
  #
  # (Wikipedia. International wird das sehr ähnlich gehandhabt)
  #
  # Mit app/javascript/admin/TravelerFields.vue synchron halten.
  def price_category_by_age # rubocop:disable Metrics/CyclomaticComplexity
    if (age = age(start_date))
      bday       = birthday?(start_date)
      categories = inquiry.traveler_price_categories

      # skip category check if no categories present - this is (only?) used in tests,
      # where creating the whole dependency tree is deemed to expensive/complicated
      return :adults unless categories

      {
        children_under_6:  6,
        children_under_12: 12,
      }.each do |cat, max|
        # return cat if age matches and prices for cat exist
        return cat if (age < max || (age == max && bday)) && categories.include?(cat.to_s)
      end
    end

    :adults
  end

  def stays_over?(night)
    start_date <= night.evening && end_date >= night.morning
  end

  private

  def take_dates
    self.start_date ||= inquiry.start_date
    self.end_date   ||= inquiry.end_date
  end
end
