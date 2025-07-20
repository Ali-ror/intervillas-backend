# "Erzeugt" eine Abrechnung aus einer Buchung
#
# Die Abrechnung eines Mietvorgangs beinhaltet die Abrechungen für die Mietobjekte
# und erzeugt hieraus Abrechnungsdokumente für Mieter und Eigentümer.
# Da bei einem Mietvorgang mehrere Eigentümer beteiligt sein können, können auch
# mehrere Abrechnungsdokumente für die Eigentümer entstehen.
#
# Abgerechnet wird ein Mietvorgang nach dem Mietzeitraum durch Eintragen der Mietnebenkosten
# unter /admin/billings.
# Hierbei entstehen dann die Datensätze VillaBilling und BoatBilling.
#
class Billing
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  BILLABLE_ORDER = %w[Villa Boat].freeze

  def self.find(id)
    inq = Inquiry.includes(
      :boat_billings,
      :villa_billings,
      :customer,
      :booking,
      :cancellation,
    ).find(id)

    # handles cancellation vs. booking
    inq.to_billing
  end

  attr_accessor :booking

  delegate :id, :to_param, :to_key, :persisted?,
    :inquiry, :inquiries, :villa, :boat,
    to: :booking

  delegate :customer, :number,
    to: :inquiry

  def to_model
    self
  end

  def initialize(booking)
    @booking = booking
  end

  def tenant_billing
    @tenant_billing ||= Billing::Tenant.new customer, booking, *billings
  end

  def owner_billings
    @owner_billings ||= billings_by_owner.map { |owner, b|
      Billing::Owner.new owner, booking, *b
    }
  end

  def billings
    @billings ||= booking.billings.sort { |a, b|
      ai = BILLABLE_ORDER.index(a.rentable.class.name)
      bi = BILLABLE_ORDER.index(b.rentable.class.name)

      default = BILLABLE_ORDER.size + 1
      (ai || default) <=> (bi || default)
    }
  end

  def billings_persisted?
    # Falle: `[].all?(&:foo?) #=> true`
    billings.any? && billings.all?(&:persisted?)
  end

  private

  # Gibt einen Hash<User, [VillaBilling, BoatBilling, ...]> zurück
  def billings_by_owner(reload = false)
    @billings_by_owner = nil if reload

    @billings_by_owner ||= billings.each_with_object(Hash.new { |h, k| h[k] = [] }) { |b, by_owner|
      by_owner[b.owner] << b
    }
  end
end
