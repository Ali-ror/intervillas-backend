#
# Gemeinsame Attribute aller mietbaren Objekte
#
# - Villa
# - Boat
# - ...
#
# Ein "Rentable" zeichnet sich dadurch aus, dass
#
# - es einem Eigentümer (owner) gehört,
# - dazu Mietanfragen (rentable_inquiries) vorliegen, und
# - nach Mietende eine Abrechnung (billing) erstellt wird.
#
module Rentable
  extend ActiveSupport::Concern

  included do
    as          = name.demodulize.underscore
    x_inquiries = "#{as}_inquiries"
    x_billings  = "#{as}_billings"

    %i[owner manager].each do |contact|
      belongs_to contact,
        autosave:   true,
        class_name: "Contact",
        optional:   true # optional, weil NULL erlaubt
    end

    has_many x_inquiries.to_sym
    _reflections["rentable_inquiries"] = _reflections[x_inquiries]
    alias_method :rentable_inquiries, x_inquiries

    has_many x_billings.to_sym
    _reflections["billings"] = _reflections[x_billings]
    alias_method :billings, x_billings

    has_many :inquiries, through: x_inquiries
    has_many :bookings, -> { where(inquiries: { cancelled_at: nil }) },
      through: :inquiries do
      # Prueft, ob der Zeitraum bereits belegt ist
      def period_available?(start_date, end_date, booking_ignore = nil)
        bookings = booked.clashes(start_date, end_date)
        bookings = bookings.where.not(bookings: { inquiry_id: booking_ignore.id }) if booking_ignore.try(:inquiry_id)
        bookings.empty?
      end
    end

    has_many :blockings
  end

  def events(start_date, end_date)
    Grid::View.between(start_date, end_date).rentable(model_name.to_s, [id])
  end

  def utilization_in_year(year, occupancies = nil)
    year_date = Date.new year, 1, 1
    utilization(year_date.beginning_of_year, year_date.end_of_year, occupancies)
  end

  def utilization(start_date, end_date, occupancies = nil)
    occupancies ||= events(start_date, end_date)

    sum = occupancies.map(&:half_days_count).sum

    # Die Halbtage, die nicht exakt im angefragten Bereich liegen wieder abziehen
    sum -= occupancies.map { |occ|
      occ.half_days_not_in(start_date, end_date).count
    }.sum

    ((0.5 * sum * 100) / (end_date - start_date + 1)).round
  end

  def utilization_in_year_by_month(year)
    utilization = {}

    12.times do |n|
      month_no   = n + 1
      month_date = Date.new year, month_no, 1

      utilization[month_no] = utilization(month_date.beginning_of_month, month_date.end_of_month)
    end

    utilization
  end

  def blocked_dates(except_inquiry: nil, external: false)
    date = Date.current

    scopes = {
      bookings:  bookings.after(date),
      blockings: blockings.not_ignored.after(date),
    }

    if except_inquiry
      scopes[:bookings]  = scopes[:bookings].where.not(inquiry_id: except_inquiry)
      scopes[:blockings] = scopes[:blockings].where.not(id: except_inquiry)
    end

    scopes[:blockings] = scopes[:blockings].where(ical_uid: nil) unless external

    scopes[:bookings] + scopes[:blockings]
  end

  def notify_contacts(...)
    notify_owner_contact(...)
    notify_manager_contact(...)
  end

  def notify_owner_contact(inquiry:, text:, action: nil)
    return if owner.blank? || owner.email_addresses.empty?

    if action.to_s == "book"
      # owners shall receive a booking confirmation (support#717)
      template = is_a?(Boat) ? "boat_owner_booking_message" : "owner_booking_message"
      text     = nil
    else
      template = "note_mail"
      text     = [text, action].compact.join("\x03")
    end

    inquiry.messages.create!(recipient: owner, template:, text:)
  end

  def notify_manager_contact(inquiry:, text:, action: nil)
    return if manager.blank? || manager.email_addresses.empty?

    inquiry.messages.create!(
      recipient: manager,
      template:  "note_mail",
      text:      [text, action].compact.join("\x03"),
    )
  end
end
