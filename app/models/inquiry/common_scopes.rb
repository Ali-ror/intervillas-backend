module Inquiry::CommonScopes
  extend ActiveSupport::Concern

  included do
    scope :for_villa, ->(villa_id) {
      joins(:villa_inquiry).where villa_inquiries: { villa_id: villa_id }
    }

    scope :for_rentable, ->(rentable_type, rentable_id) {
      joins(:"#{rentable_type}_inquiry")
        .where :"#{rentable_type}_inquiries" => { "#{rentable_type}_id" => rentable_id }
    }

    scope :between_time, ->(start_date, end_date, rentable: :villa) {
      q = "#{rentable}_inquiries.start_date < :end_date AND #{rentable}_inquiries.end_date > :start_date"
      joins(:"#{rentable}_inquiry").where(q, start_date: start_date, end_date: end_date)
    }

    scope :between, ->(start, endd) {
      between_time Time.at(start.to_i), Time.at(endd.to_i)
    }
  end
end
