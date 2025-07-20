module Inquiry::Reviews
  extend ActiveSupport::Concern

  WITHOUT_REVIEWS_QUERY = <<~SQL.squish.freeze
    (villa_inquiries.end_date BETWEEN '2014-12-01' AND :date) AND
      bookings.inquiry_id NOT IN (SELECT DISTINCT inquiry_id FROM reviews)
  SQL

  included do
    has_one :review

    scope :without_reviews, -> {
      joins(:villa_inquiry, :booking)
        .where WITHOUT_REVIEWS_QUERY, date: 10.days.ago
    }
  end

  # build_review ist schon vergeben...
  def prepare_review
    review || create_review!({}) do |r|
      r.villa_id = villa.id
      r.name     = customer.last_name
      r.city     = customer.city
    end
  end
end
