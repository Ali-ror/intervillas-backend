# == Schema Information
#
# Table name: blockings
#
#  id          :integer          not null, primary key
#  comment     :text             not null
#  end_date    :date             not null
#  ical_uid    :string
#  ignored     :boolean          default(FALSE), not null
#  start_date  :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  boat_id     :integer
#  calendar_id :bigint
#  villa_id    :integer
#
# Indexes
#
#  fk__blockings_boat_id                        (boat_id)
#  fk__blockings_villa_id                       (villa_id)
#  index_blockings_on_calendar_id               (calendar_id)
#  index_blockings_on_calendar_id_and_ical_uid  (calendar_id,ical_uid) UNIQUE
#
# Foreign Keys
#
#  fk_blockings_boat_id   (boat_id => boats.id)
#  fk_blockings_villa_id  (villa_id => villas.id)
#  fk_rails_...           (calendar_id => calendars.id) ON DELETE => nullify
#
class Blocking < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :villa, optional: true # optional, weil NULL erlaubt
  belongs_to :boat, optional: true # optional, weil NULL erlaubt
  belongs_to :calendar, optional: true

  after_commit on: :create do
    villa&.booking_pal_product&.update_remote_prices!
  end

  after_commit on: :update do
    if saved_change_to_start_date? || saved_change_to_end_date? || saved_change_to_ignored?
      villa&.booking_pal_product&.update_remote_prices!
    end
  end

  after_commit on: :destroy, unless: :ignored? do
    villa&.booking_pal_product&.update_remote_prices!
  end

  scope :for_villa,    ->(villa_id) { where(villa_id:) }
  scope :for_rentable, ->(rentable_type, rentable_id) { where("#{rentable_type}_id" => rentable_id) }

  scope :between_time, ->(start_date, end_date) {
    where "start_date < :end_date AND end_date > :start_date",
      start_date:,
      end_date:
  }

  scope :between, ->(start_date, end_date) {
    between_time Time.zone.at(start_date.to_i), Time.zone.at(end_date.to_i)
  }

  scope :in_year, ->(year = Date.current.year) {
    s = Date.new(year, 1, 1)
    e = Date.new(year, 12, 31)

    where <<~SQL.squish, start_date: s, end_date: e
         start_date BETWEEN :start_date AND :end_date
      OR end_date BETWEEN :start_date AND :end_date
    SQL
  }
  scope :after, ->(start_date) { where "end_date > ?", start_date }

  scope :clashes, ->(start_date, end_date) {
    not_ignored.where "start_date < :end_date AND end_date > :start_date",
      start_date:,
      end_date:
  }

  scope :select_villa_ids, -> { where.not(villa_id: nil).select(:villa_id) }

  scope :not_ignored, -> { where(ignored: false) }

  def ignore!
    update ignored: true
  end

  def rentable
    villa || boat
  end

  def dates(_rentable = :not_used)
    date_range.to_a
  end

  def date_range
    start_date..end_date
  end

  def name
    comment
  end

  def event_title
    "#{number} #{name} #{I18n.t 'states.blocked'}"
  end

  def number
    "IV-B#{id}"
  end

  def recently_created?
    created_at > 2.weeks.ago
  end

  def state
    "blocked"
  end

  def to_event_hash(*)
    {
      id:,
      villa_id:,
      boat_id:,
      title:     event_title,
      allDay:    true,
      start:     start_date,
      end:       end_date,
      className: ["blocked", recently_created? ? "fresh" : nil].compact.join(" "),
      blocked:   true,
      path:      url_helpers.edit_admin_blocking_path(self),
    }
  end

  def start_datetime
    start_date.to_datetime.change hour: (villa_id ? 16 : 8)
  end

  def end_datetime
    end_date.to_datetime.change hour: (villa_id ? 8 : 16)
  end

  def inquiry
    self
  end

  def booking
    self
  end

  def dates_for(*)
    [start_date, end_date]
  end

  def clashing_bookings_and_blockings
    booked  = VillaInquiry.where(villa_id:).clashes(*dates_for).booked
    blocked = Blocking.where(villa_id:).clashes(*dates_for).not_ignored.where.not(id:)

    [*booked.to_a, *blocked.to_a]
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end
end
