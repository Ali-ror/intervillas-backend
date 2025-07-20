#
# Holt alle Zahlungseingänge für den Jahresabschluss aus der Datenbank.
#
# Dabei ist es wichtig lediglich die Zahlungseingänge für ein Jahr, die sich
# auf Buchungen ab dem Folgejahr beziehen zu betrachten.
#
# Hat ein paar Hilfsmethoden, die den Zugriff auf assoziierte Objekte
# performanter macht.
#
#  boat_id              :integer
#  customer_id          :integer
#  inquiry_id           :integer          not null
#  max_end_date         :date             not null
#  min_start_date       :date             not null
#  paid_total           :decimal(10, 2)   not null
#  state                :string
#  villa_id             :integer
#
class Balance < SimpleDelegator # rubocop:disable Metrics/ClassLength
  include Memoizable

  BALANCE_QUERY = <<~SQL.squish.freeze
    select
        b.inquiry_id
      , pv.state
      , i.customer_id
      , i.currency
      , vi.villa_id
      , bi.boat_id
      , coalesce(vi.start_date, bi.start_date) as min_start_date
      , coalesce(vi.end_date, bi.end_date)     as max_end_date
      , p.sum                                  as paid_total
    from bookings b

    left join inquiries       i  on i.id          = b.inquiry_id
    left join villa_inquiries vi on vi.inquiry_id = i.id
    left join boat_inquiries  bi on bi.inquiry_id = i.id
    left join payments_view   pv on pv.inquiry_id = i.id

    left join (
      select inquiry_id, sum("sum")
      from payments
      where paid_on is not null
        and extract('year' from paid_on) <= ?
      group by inquiry_id
    ) p on p.inquiry_id = b.inquiry_id

    where p.sum > 0
      and extract('year' from coalesce(vi.start_date, bi.start_date)) >= ?
      and currency = ?
  SQL

  attr_reader :currency, :year

  def initialize(year, currency)
    @currency = currency
    @year     = year
    super Booking.find_by_sql [BALANCE_QUERY, year - 1, year, currency]
  end

  memoize(:customer_ids) { map(&:customer_id).compact.uniq }
  memoize(:villa_ids)    { map(&:villa_id).compact.uniq }
  memoize(:boat_ids)     { map(&:boat_id).compact.uniq }

  memoize(:customers) { Customer.where id: customer_ids }
  memoize(:villas)    { Villa.where id: villa_ids }
  memoize(:boats)     { Boat.where id: boat_ids }

  def sum
    paid_total = super(&:paid_total)
    Currency::Value.make_value(paid_total, currency)
  end

  # Findet den Mieter einer Buchung.
  #
  # Holt den Record aus dem Cache (booking.customer würde einen neuen Query
  # absetzen).
  def customer(booking)
    customers.find { |c| c.id == booking.customer_id }
  end

  # Findet die Villa zu eine Buchung.
  #
  # Holt den Record aus dem Cache (booking.villa würde einen neuen Query
  # absetzen).
  def villa(booking)
    villas.find { |v| v.id == booking.villa_id }
  end

  # Findet das Boot zu einer Buchung.
  #
  # Holt den Record aus dem Cache (booking.boat würde einen neuen Query
  # absetzen).
  def boat(booking)
    boats.find { |b| b.id == booking.boat_id }
  end

  def rentables(booking)
    [villa(booking), boat(booking)].compact
  end

  CSV_HEADER = [
    "Buchung",
    "Extern",
    "Villa",
    "Boot",
    "von",
    "bis",
    "eingegangen",
    "Währung",
    "Zahlung: Konto",
    "Zahlung: Eingang",
    "Zahlung: Betrag",
  ].freeze
  private_constant :CSV_HEADER

  def to_csv(*)
    CSV.generate do |csv|
      csv << CSV_HEADER
      each do |booking|
        csv << booking_to_csv(booking)

        booking.payments.where("paid_on is not null and extract('year' from paid_on) <= ?", @year - 1).each do |payment|
          csv << payment_to_csv(booking, payment)
        end
      end
    end
  end

  alias to_comma to_csv

  private

  def booking_to_csv(booking)
    [
      booking.inquiry.id,
      booking.inquiry.external ? "ja" : "nein",
      villa(booking).try(:admin_display_name),
      boat(booking).try(:admin_display_name),
      booking.min_start_date,
      booking.max_end_date,
      format("%0.2f", booking.paid_total.value).sub(".", ","),
      booking.paid_total.currency,
    ]
  end

  def payment_to_csv(booking, payment)
    [
      booking.inquiry_id,
      *([nil] * 6),
      booking.paid_total.currency,
      I18n.t(payment.scope, scope: "payments.scope", default: "n/a"),
      payment.paid_on,
      format("%0.2f", payment.sum).sub(".", ","),
    ]
  end
end
