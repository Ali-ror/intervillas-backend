# == Schema Information
#
# Table name: payments_view
#
#  ack_downpayment  :boolean
#  booked_on        :date
#  diff             :decimal(10, 2)
#  downpayment_date :date
#  downpayment_sum  :decimal(10, 2)
#  end_date         :date
#  external         :boolean
#  inquiry_id       :integer          primary key
#  late             :boolean
#  remainder_date   :date
#  remainder_sum    :decimal(10, 2)
#  start_date       :date
#  state            :string
#  total_payments   :decimal(10, 2)
#

# Alle Buchungen/Zahlungen von nicht-externen Anfragen, die noch nicht
# vollständig bezahlt sind.
#
# Basiert auf einem View, der die Suchlogik auf DB-Ebene kapselt.
class Payment::View < ApplicationRecord
  self.table_name  = "payments_view"
  self.primary_key = :inquiry_id

  belongs_to :inquiry
  has_one :customer,
    through: :inquiry

  has_one :booking,
    through:     :inquiry,
    foreign_key: :inquiry_id

  has_many :messages, -> { where template: "payment_reminder" },
    through: :inquiry

  # offene, nicht mehr abrechenbare Posten aus den Jahren vor 2015 sollen
  # ignoriert werden (dm, Telefonat mit Urs, 2015/11/18)
  IGNORE_OVERDUE_BEFORE = 2015

  # Betrag (absolut), um den tatsächlichen Zahlungseingänge vom Anzahlungsbetrag
  # abweichen dürfen (hat mit Rundung auf nächsten 10er zu tun).
  #
  # Siehe auch PaymentDeadlines::Deadline
  DOWNPAYMENT_DELTA = 10

  # mit #overdue? synchron halten
  OVERDUE_QUERY = <<~SQL.squish.freeze
        external = :external
    and extract('year' from end_date) >= :date
    and ((
              late = 'f'
          and ack_downpayment = 'f'
          and current_date >= downpayment_date
          and total_payments < (downpayment_sum - :delta)
        ) or (
              current_date >= remainder_date
          and total_payments < remainder_sum
        ))
  SQL

  scope :overdue,  -> { where OVERDUE_QUERY, date: IGNORE_OVERDUE_BEFORE, delta: DOWNPAYMENT_DELTA, external: false }
  scope :external, -> { where OVERDUE_QUERY, date: IGNORE_OVERDUE_BEFORE, delta: DOWNPAYMENT_DELTA, external: true }
  scope :unpaid,   -> { where "diff > 0" }

  scope :downpayment_nack,   -> { where ack_downpayment: false }
  scope :downpayment_ack,    -> { where ack_downpayment: true }
  scope :acked_downpayments, -> { DownpaymentSecurity.acceptable_scope(downpayment_ack) }

  # mit OVERDUE_QUERY synchron halten
  def overdue?
    downpayment_overdue? || remainder_overdue?
  end

  def downpayment_date
    super&.to_date
  end

  def remainder_date
    super&.to_date
  end

  def downpayment_overdue?
    end_date.year >= IGNORE_OVERDUE_BEFORE &&
      !late?                               &&
      !ack_downpayment                     &&
      Time.current >= downpayment_date     &&
      total_payments < (downpayment_sum - DOWNPAYMENT_DELTA)
  end

  def remainder_overdue?
    end_date.year >= IGNORE_OVERDUE_BEFORE &&
      total_payments < remainder_sum       &&
      Time.current >= remainder_date
  end

  def downpayment_due_balance
    downpayment_sum - total_payments
  end

  def remainder_due_balance
    diff
  end

  def acceptable_downpayment_security?
    DownpaymentSecurity.new(
      late:            late,
      paid_sum:        total_payments,
      downpayment_sum: downpayment_sum,
    ).acceptable?
  end

  include Currency::Model
  currency_values :downpayment_sum, :remainder_sum, :diff, :total_payments

  concerning :CSVExport do
    included do
      comma do
        inquiry_id           "B-Nr."
        csv_late             "kurzfristige Buchung?"
        csv_downpayment_sum  "Betrag Anzahlung"
        csv_downpayment_date "Frist Anzahlung"
        remainder_date       "Frist Restzahlung"
        remainder_sum        "Betrag Restzahlung"
        total_payments       "Total Eingang"
        diff                 "Differenz"
      end
    end

    private

    def csv_late
      "ja" if late?
    end

    def csv_downpayment_sum
      downpayment_sum unless late?
    end

    def csv_downpayment_date
      downpayment_date unless late?
    end
  end
end
