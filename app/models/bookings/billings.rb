module Bookings::Billings
  extend ActiveSupport::Concern

  included do
    scope :with_billing_in, ->(date, whole_year = false, group_by_start_date = true) {
      scope = includes(inquiry: [
        villa_inquiry:  :villa,
        boat_inquiry:   :boat,
        boat_billings:  [:charges, { rentable: :owner }],
        villa_billings: [:charges, { rentable: :owner }],
      ]).joins(inquiry: :villa_inquiry).reorder(Arel.sql("villa_inquiries.end_date"))

      case [!!group_by_start_date, !!whole_year] # rubocop:disable Style/DoubleNegation
      when [true, true]
        scope.where <<~SQL.squish.freeze, year: date.year
          extract(year from villa_inquiries.start_date) = :year
        SQL
      when [true, false]
        scope.where <<~SQL.squish.freeze, month: date.beginning_of_month.to_date
          date_trunc('month', villa_inquiries.start_date)::date = :month
        SQL
      when [false, true]
        scope.where <<~SQL.squish.freeze, year: date.year
          extract(year from summary_on) = :year
        SQL
      when [false, false]
        scope.where summary_on: date.beginning_of_month.to_date
      end
    }

    delegate :to_billing, :billings, to: :inquiry
  end
end
