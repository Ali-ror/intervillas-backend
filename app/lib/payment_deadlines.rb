class PaymentDeadlines # rubocop:disable Metrics/ClassLength
  include Memoizable

  attr_reader :booked_on, :start_date, :total, :deposits, :payments,
    :paid_total, :difference, :currency, :external

  delegate :each, :select,
    to: :deadlines

  # Non-late bookings before this date need to downpay 20%, bookings on
  # of after this date 35%. See #downpayment_percentage.
  #
  # Date must be kept in sync with the payments_view DB view, otherwise
  # the due-payments query will deliver wrong results.
  DOWNPAYMENT_PERCENTAGE_CHANGED_ON = "2022-02-02".to_date

  # (abstrakte) Klasse, die eine Zahlungsfrist darstellt, siehe konkrete
  # Implementierungen in DownpaymentDeadline und RemainderDeadline.
  #
  # @param [:downpayment, :remainder] name            wird für Lokalisierung gebraucht
  # @param [Date]                     date            Zahlungsfrist
  # @param [BigDecimal]               total_sum       zu zahlender Gesamtbetrag
  # @param [BigDecimal]               paid_sum        bereits gezahlter Betrag
  # @param [BigDecimal, nil]          allowed_delta   erlaubte Differenz bei Anzahlungen
  # @param [Boolean]                  ack             bei Anzahlungen: Differenz wurde gewährt
  # @param [Boolean]                  external        ignoriert überfällige Zahlungen bei ext. Buchungen
  Deadline = Struct.new(:name, :date, :total_sum, :paid_sum, :allowed_delta, :ack, :external, keyword_init: true) do
    # Betrag, der zum Datum `date` eingegangen sein muss (ist <= `total_sum`)
    attr_reader :deadline_sum

    # für Ausgabezwecke
    attr_reader :display_sum

    # welcher Betrag fehlt noch?
    def due_balance
      deadline_sum - paid_sum
    end

    def paid?
      due_balance <= 0
    end

    # ist der Betrag fällig?
    def overdue?
      !external && !ack && date <= Date.current && paid_sum < (deadline_sum - allowed_delta)
    end

    # rundet auf den nächsten 10er
    def round_nicely(val)
      (val / 10.0).ceil! * 10
    end
  end

  class DownpaymentDeadline < Deadline
    def initialize(date:, total_sum:, paid_sum:, late:, ack:, external:, percentage:, deposits:) # rubocop:disable Metrics/ParameterLists
      raise ArgumentError, "no downpayment for late bookings allowed" if late

      # erlaubte Differenz bei Zahlungseingängen -- bei Rundungen auf nächsten 10er
      # können Abweichungen in Zahlungseingang (für Anzahlung) und Betrag in
      # (aktueller) E-Mail aufgetreten sein, die wir hier erlauben
      super(
        name:          :downpayment,
        date:          date,
        total_sum:     total_sum - deposits,
        paid_sum:      paid_sum,
        allowed_delta: Payment::View::DOWNPAYMENT_DELTA,
        ack:           ack,
        external:      external,
      )

      @ack          = ack
      @display_sum  = round_nicely((total_sum - deposits) * percentage)
      @deadline_sum = display_sum
    end
  end

  class RemainderDeadline < Deadline
    def initialize(date:, total_sum:, paid_sum:, late:, external:, percentage:, deposits:) # rubocop:disable Metrics/ParameterLists
      super(
        name:          :remainder,
        date:          date,
        total_sum:     total_sum,
        paid_sum:      paid_sum,
        allowed_delta: 0,
        ack:           false,
        external:      external,
      )

      @display_sum  = total_sum
      @display_sum -= round_nicely((total_sum - deposits) * percentage) unless late
      @deadline_sum = total_sum
    end
  end

  def self.from_inquiry(inquiry)
    new \
      start_date:      (inquiry.villa_inquiry || inquiry.boat_inquiry).start_date,
      booked_on:       (inquiry.booked_at || Date.current).to_date,
      total:           inquiry.clearing.total,
      deposits:        inquiry.clearing.deposits.sum { |dep| dep.price },
      payments:        inquiry.payments,
      ack_downpayment: inquiry.ack_downpayment,
      currency:        inquiry.currency,
      external:        inquiry.external
  end

  def initialize(booked_on:, start_date:, total:, deposits:, payments:, currency:, external:, ack_downpayment: false) # rubocop:disable Metrics/ParameterLists
    @booked_on  = booked_on.to_date
    @start_date = start_date.to_date
    @total      = total.round(3) # person price might be 11.6666667, so the total might be skewed by 0.000000X
    @deposits   = deposits
    @payments   = payments
    @ack_dp     = !!ack_downpayment # rubocop:disable Style/DoubleNegation
    @currency   = currency

    # payments.sum(&:paid_sum) wirft Fehler!?
    @paid_total = Currency::Value.new(payments.map(&:paid_sum).sum, currency)
    @difference = total - paid_total
    @late       = booked_on.to_date >= start_date - 38.days
    @external   = external
  end

  def late?
    @late
  end

  def overdue?
    !external && overdues.any?
  end

  def payments?
    @paid_total > 0
  end

  def due_sum
    remainder_deadline.deadline_sum - paid_total
  end

  def first_unpaid
    return remainder_deadline if downpayment_deadline.nil? || downpayment_deadline.paid?

    downpayment_deadline
  end

  def name
    deadlines.map(&:name).join("+")
  end

  def acceptable_downpayment_security?
    DownpaymentSecurity.new(
      late:            late?,
      paid_sum:        paid_total,
      downpayment_sum: downpayment_deadline&.deadline_sum,
    ).acceptable?
  end

  memoize :due_balances do
    overdues.any? ? overdues.last.due_balance : Currency::Value.new(0, currency)
  end

  # @return Hash[Date => Sum]
  #         Liste mit Fälligkeits-Daten und fälligen Beträgen.
  memoize :overdues do
    deadlines.select(&:overdue?)
  end

  # 7 Tage nach der Buchung müssen 35% angezahlt sein (bei kurzfristigen
  # Buchungen ist booked_on+30d >= start_date), 30 Tage vor Beginn muss alles
  # bezahlt sein.
  #
  # @return Hash[Date => Sum]
  #         Mapping von Fälligkeits-Daten auf Betrag, der bis dahin fällig ist.
  memoize :deadlines do
    [downpayment_deadline, remainder_deadline].compact
  end

  memoize :downpayment_deadline do
    next if late?

    DownpaymentDeadline.new(
      date:       booked_on + 7.days,
      total_sum:  total,
      paid_sum:   paid_total,
      late:       late?,
      ack:        @ack_dp,
      external:   external,
      percentage: downpayment_percentage,
      deposits:   deposits,
    )
  end

  memoize :remainder_deadline do
    # kurzfristige Buchungen sind am Tag der Buchung ("sofort") fällig
    due_date = late? ? booked_on : (start_date - 30.days)

    RemainderDeadline.new(
      date:       due_date,
      total_sum:  total,
      paid_sum:   paid_total,
      late:       late?,
      external:   external,
      percentage: downpayment_percentage,
      deposits:   deposits,
    )
  end

  memoize :downpayment_percentage do
    if booked_on < DOWNPAYMENT_PERCENTAGE_CHANGED_ON
      0.2.to_d # 20%
    else
      0.35.to_d # 35%
    end
  end
end
