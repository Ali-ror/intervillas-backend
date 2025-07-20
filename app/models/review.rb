# == Schema Information
#
# Table name: reviews
#
#  id           :integer          not null, primary key
#  city         :string
#  deleted_at   :datetime
#  name         :string
#  published_at :datetime
#  rating       :integer
#  text         :text
#  token        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inquiry_id   :integer          not null
#  message_id   :integer
#  villa_id     :integer          not null
#
# Indexes
#
#  fk__reviews_booking_id       (inquiry_id)
#  fk__reviews_message_id       (message_id)
#  fk__reviews_villa_id         (villa_id)
#  index_reviews_on_inquiry_id  (inquiry_id)
#  index_reviews_on_token       (token) UNIQUE
#  index_reviews_on_villa_id    (villa_id)
#
# Foreign Keys
#
#  fk_rails_...           (inquiry_id => bookings.inquiry_id) ON DELETE => cascade
#  fk_reviews_message_id  (message_id => messages.id)
#  fk_reviews_villa_id    (villa_id => villas.id) ON DELETE => restrict
#

class Review < ApplicationRecord
  include Digineo::Token
  include Reviews::Ratings
  include Reviews::Mailing
  include Reviews::Presentation

  # bei älteren Reviews fehlt das Datum?
  START_DATE = DateTime.parse("2014-12-01T00:00:00Z")

  belongs_to :villa
  belongs_to :inquiry

  has_one :booking,
    through: :inquiry

  scope :undeleted,   -> { where deleted_at: nil }
  scope :sorting,     ->(o) { reorder o }
  scope :unpublished, -> { where published_at: nil }
  scope :published,   -> { where.not published_at: nil }
  scope :with_text,   -> { where.not text: [nil, ""] }
  scope :with_rating, -> { where.not rating: nil }
  scope :with_name,   -> { where.not name: [nil, ""] }

  # für Startseite: n der besten Bewertungen
  scope :complete,     -> { published.with_text.with_rating.with_name }
  scope :best_ratings, ->(n = 10) { complete.order(Arel.sql("rating DESC, published_at DESC, random()")).limit(n) }

  scope :on_domain, ->(d) {
    scope = d.is_a?(Domain) ? { id: d.id } : { name: d }
    joins(villa: :domains).where(domains: scope)
  }

  def complete?
    rating.present? && name.present? && text.present?
  end

  def incomplete?
    !complete?
  end

  def published?
    published_at?
  end

  def archived?
    deleted_at?
  end
end
