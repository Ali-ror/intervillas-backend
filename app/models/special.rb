# == Schema Information
#
# Table name: specials
#
#  created_at  :datetime         not null
#  description :string           not null
#  end_date    :date             not null
#  id          :integer          not null, primary key
#  percent     :integer          not null
#  start_date  :date             not null
#  updated_at  :datetime         not null
#

class Special < ApplicationRecord
  validates :percent, :start_date, :end_date, :description, presence: true
  validates :percent, numericality: { only_integer: true, greater_than_or_equal_to: -100, less_than_or_equal_to: 100 }

  has_and_belongs_to_many :villas, -> { where(active: true) } do
    # gibt die villen zurueck, welche noch mind 7 Tage im Aktionszeitraum verfuegbar haben
    def available
      owner = proxy_association.owner
      select do |villa|
        has_7_days_available?(villa, owner)
      end
    end

    def has_7_days_available?(villa, owner)
      @bookings ||= (
        Booking.booked
          .between_time(owner.start_date - 6, owner.end_date + 6)
          .where(villa_inquiries: { villa_id: owner.villas.reorder(:id).pluck(:id) })
          .select("villa_inquiries.start_date, villa_inquiries.end_date, villa_id, bookings.inquiry_id") +

        Blocking
          .between_time(owner.start_date - 6, owner.end_date + 6)
          .where(villa_id: owner.villas.reorder(:id).pluck(:id))
          .select("start_date, end_date, villa_id")
      ).group_by(&:villa_id)

      bookings        = @bookings.fetch villa.id, []
      booked_dates    = bookings.map(&:dates).flatten.compact
      available_dates = ([owner.start_date, Date.current].max..owner.end_date).to_a - booked_dates
      counter         = 0
      available       = false

      available_dates.each_cons(2) do |date, next_day|
        if next_day - date == 1
          counter += 1
          # counter enthält die nächte
          if counter >= NightsCalculator::ABSOLUTE_MINIMUM_DAYS - 1
            available = true
            counter   = 0
            break
          end
        else
          counter = 0
        end
      end
      available
    end

    def available_with_limit(limit)
      owner = proxy_association.owner
      lazy.select { |villa|
        has_7_days_available?(villa, owner)
      }.first(limit)
    end
  end

  scope :of_type, ->(type) { where description: type }
  scope :current, ->(date = nil) { where "start_date <= :today AND end_date >= :today", today: date || Date.current }

  def discount(regular_price)
    price = regular_price - (regular_price * percent / 100)
    (price * 100).round / 100.0
  end

  def date_ranges(*)
    [start_date..end_date]
  end
end
