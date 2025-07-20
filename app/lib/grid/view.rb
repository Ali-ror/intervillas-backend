# == Schema Information
#
# Table name: calendar_grid_view
#
#  end_date         :date
#  inquiry_id       :integer          primary key
#  regular_inquiry  :boolean
#  rentable_id      :integer
#  rentable_type    :text
#  start_date       :date
#

module Grid
  class View < ApplicationRecord
    include Dateable

    self.table_name  = "calendar_grid_view"
    self.primary_key = :inquiry_id

    belongs_to :inquiry
    belongs_to :rentable, polymorphic: true
    belongs_to :blocking,
      primary_key: :id,
      foreign_key: :inquiry_id

    has_one :booking,       through: :inquiry
    has_one :villa_inquiry, through: :inquiry
    has_one :boat_inquiry,  through: :inquiry
    has_one :customer,      through: :inquiry

    scope :for_calendar, -> {
      includes(
        :rentable,
        :booking,
        :blocking,
        :boat_inquiry,
        villa_inquiry: :travelers,
        inquiry:       %i[customer villa boat],
      ).order(rentable_id: :asc, start_date: :asc)
    }

    scope :between, ->(sdate, edate) {
      where("(? - end_date)::bigint * (start_date - ?)::bigint >= 0", sdate, edate)
    }

    scope :capped_between, ->(sdate, edate) {
      cap_sdate = sanitize_sql_array ["CASE WHEN start_date < ? THEN ? ELSE start_date END AS start_date", sdate, sdate]
      cap_edate = sanitize_sql_array ["CASE WHEN end_date > ? THEN ? ELSE end_date END AS end_date", edate, edate]

      between(sdate, edate).select(Arel.star, Arel.sql(cap_sdate), Arel.sql(cap_edate))
    }

    scope :rentable, ->(type, ids) {
      where(rentable_type: type, rentable_id: ids)
    }

    def rentable_inquiry
      return blocking unless regular_inquiry?

      case rentable_type
      when "Villa" then villa_inquiry
      when "Boat"  then boat_inquiry
      end
    end
  end
end
