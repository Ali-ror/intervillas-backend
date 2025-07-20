# == Schema Information
#
# Table name: high_seasons
#
#  addition   :integer          default(20), not null
#  created_at :datetime         not null
#  ends_on    :date             not null
#  id         :integer          not null, primary key
#  starts_on  :date             not null
#  updated_at :datetime         not null
#

class HighSeason < ApplicationRecord
  has_and_belongs_to_many :villas

  has_many :bookings, ->(hs) { where("bookings.created_at > ?", hs.created_at) },
    through: :villas

  scope :overlaps,   ->(*dates) { where "(starts_on, ends_on) OVERLAPS (?, ?)", dates[0], dates[1] }
  scope :older_than, ->(date)   { where "created_at <= ?", date }
  scope :after,      ->(date)   { where "starts_on >= :date or ends_on >= :date", date: date }

  def name
    [starts_on.strftime("%Y"), ends_on.strftime("%y")].join("-")
  end

  def dates
    [starts_on, ends_on]
  end

  def date_range
    starts_on..ends_on
  end

  def date_ranges(*)
    [date_range]
  end

  def overlaps?(date_range)
    days_in_range(date_range) > 0
  end

  def days_in_range(q_date_range)
    q_date_range.inject(0) do |acc, booking_date|
      acc += 1 if cover?(booking_date)
      acc
    end
  end

  def group_key
    [starts_on, ends_on, addition]
  end

  def cover?(date)
    starts_on <= date && date <= ends_on
  end
end
