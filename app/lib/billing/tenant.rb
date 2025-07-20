Billing::Tenant = Struct.new(:customer, :booking, :billables) do
  def initialize(customer, booking, *billables)
    super customer, booking, billables.flatten
  end

  alias_method :recipient, :customer

  delegate :currency, :payment_method, to: :booking

  def deposits
    @deposits ||= billables.map { |b|
      [
        b.rentable.display_name,
        Billing::Position.new(:deposit, b.class.rentable, b.deposit),
      ]
    }.to_h
  end

  def total_deposit
    @total_deposit ||= deposits.values.map(&:gross).sum
  end

  def charges
    @charges ||= billables.flat_map(&:charges)
  end

  def total_charges
    @total_charges ||= charges.map(&:sub_total).sum
  end

  def total_energy
    @total_energy ||= billables.map { |b|
      b.is_a?(VillaBilling) ? b.energy.gross : 0
    }.sum
  end

  def total
    @total ||= [
      total_deposit,
      -total_energy,
      -total_charges,
    ].sum
  end

  def pdf
    @pdf ||= Billing::Pdf.new self, id_string
  end

  def date
    billables.max_by(&:updated_at).updated_at.to_date
  end

  # Datei-Name der PDF. Genereller Aufbau: "IV-$bid-Owner", wobei
  # `$bid` = Booking-ID.
  def id_string
    @id_string ||= [booking.number, "Tenant", currency].join("-")
  end
end
