Billing::Owner = Struct.new(:owner, :booking, :billables) do
  include Billing::Csv

  def initialize(owner, booking, *billables)
    super owner, booking, billables.flatten
  end

  delegate :currency, to: :booking

  alias_method :recipient, :owner

  def charges
    @charges ||= billables.flat_map(&:charges)
  end

  def accounting
    @accounting ||= billables.map { |b| b.total.net }.sum
  end

  def repeater_discount
    @repeater_discount ||= villa_billing&.repeater_discount || 0
  end

  def agency_fee
    @agency_fee ||= -billables.map(&:agency_fee).sum
  end

  def agency_commission
    @agency_commission ||= -billables.map(&:agency_commission).sum
  end

  def payout
    @payout ||= [
      accounting,
      charges.map(&:sub_total).sum,
      repeater_discount,
      agency_fee,
      agency_commission,
    ].sum
  end

  def payout_for_report
    # https://git.digineo.de/intervillas/support/issues/72#note_3480
    #
    # > Nur Häuser: payout net price
    # > Nur Boote: Regelfall: payout gross price
    #              Wenn Eigentümer das :net Flag gesetzt hat, dann auch
    #              payout net price
    # > Kombiniert 1 Abrechnung: payout net price

    if villa_billing.present? || owner.net
      payout
    else
      payout + taxes
    end
  end

  def taxes
    @taxes ||= billables.flat_map(&:total).map(&:tax).sum
  end

  def pdf
    @pdf ||= Billing::Pdf.new self, id_string
  end

  def date
    billables.max_by(&:updated_at).updated_at.to_date
  end

  def villa_billing
    @villa_billing ||= billables.find { |b| b.is_a? VillaBilling }
  end

  def boat_billing
    @boat_billing ||= billables.find { |b| b.is_a? BoatBilling }
  end

  def main_billing
    villa_billing || boat_billing
  end

  # Datei-Name der PDF. Genereller Aufbau: "IV-$bid-Owner-$type", wobei
  # `$bid` = Booking-ID und `$type` = Dinge, die abgerechnet werden.
  #
  # Beispiele für `$type`:
  #
  # - "Boat-Villa", wenn Billables ein Boat- und ein VillaBilling enthalten
  # - "Villa", wenn nur eine Villa abgerechnet wird
  # - "Boat-Car", für Mietwagen und Boot,
  # - etc.
  def id_string
    @id_string ||= [
      booking.number,
      "Owner",
      *billables.map { |b| b.class.name.demodulize.gsub(/Billing\z/, "") }.sort.uniq,
      currency,
    ].join("-")
  end
end
