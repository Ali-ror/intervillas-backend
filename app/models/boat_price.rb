# == Schema Information
#
# Table name: boat_prices
#
#  id          :integer          not null, primary key
#  amount      :integer
#  currency    :enum             default("EUR"), not null
#  disabled_at :datetime
#  subject     :string           not null
#  value       :decimal(8, 2)    not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  boat_id     :integer          not null
#
# Indexes
#
#  fk__prices_boat_id            (boat_id)
#  index_boat_prices_on_subject  (subject)
#
# Foreign Keys
#
#  fk_prices_boat_id  (boat_id => boats.id)
#

class BoatPrice < ApplicationRecord
  SUBJECTS = %w[deposit training daily].freeze

  enum :currency, {
    EUR: Currency::EUR,
    USD: Currency::USD,
  }

  belongs_to :boat, touch: true

  validates :subject,
    presence:  true,
    inclusion: { in: SUBJECTS }

  validates :amount,
    if:           ->(price) { price.subject == "daily" },
    numericality: { greater_than_or_equal_to: 0, only_integer: true }

  validates :amount,
    if:      ->(price) { price.subject != "daily" },
    absence: true

  validates :value,
    presence:     true,
    numericality: { greater_than_or_equal_to: 0 }

  validates :currency,
    presence:  true,
    inclusion: { in: Currency::CURRENCIES }

  scope :subject,    ->(s) { where subject: s }
  scope :boat,       ->(b) { where boat_id: (b.is_a?(Boat) ? b.id : b) }
  scope :boat_daily, -> { subject("daily").where.not(boat_id: nil) }
  scope :enabled,    -> { where(disabled_at: nil) }

  scope :valid_at, ->(date) {
    where "created_at <= :valid_at AND (disabled_at IS NULL OR disabled_at > :valid_at)",
      valid_at: date
  }

  scope :valid_now, -> { valid_at(Time.current) }

  delegate :to_s, :to_f,
    to: :value

  before_create :expand_validity
  after_create :disable_siblings

  def expand_validity
    date            = boat&.created_at
    self.created_at = date if date.present? && siblings.blank?
  end

  def disable_siblings
    siblings.update disabled_at: created_at
  end

  def destroy
    update disabled_at: Time.current
  end

  private

  # Vorgänger oder Nachfolger
  def siblings
    self.class
      .where.not(id:)
      .where(boat_id:, subject:, amount:, currency:)
  end
end
