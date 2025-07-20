#
# OwnerClearing gruppiert abgrechnete Buchungen für einen bestimmten
# Eigentümer.
#
class OwnerClearing
  # inquiries sollte ein Array (oder AR::Relation) von Inquiry-Objekten
  # ein. Im Fall einer AR::Relation ist es sinnvoll (lies: vorgesehen),
  # dass die referenzierten Buchungen alle den selben summary_on-Wert
  # haben (z.B. für Gruppierungen nach Monat oder Jahr).
  #
  # Siehe Inquiry.cleared_for Scope und Admin::ClearingsController
  def self.from(inquiries)
    groups = inquiries.each_with_object({}) { |inquiry, group|
      inquiry.to_billing.owner_billings.each do |billings|
        owner             = billings.owner
        group[owner.id] ||= new(owner, inquiry.currency)
        group[owner.id].add(inquiry, billings)
      end
    }
    groups
      .sort_by { |_, oc| oc.owner.to_s } # nach Name/Firma sortieren
      .map     { |_, oc| [oc.owner.id, oc] }
      .to_h
  end

  Summary = Struct.new(:inquiry, :payout, :rentables)

  attr_reader :owner
  attr_reader :currency
  attr_reader :summaries
  attr_reader :villas, :boats
  attr_reader :total_payout

  def initialize(owner, currency)
    @owner        = owner
    @currency     = currency
    @total_payout = 0.to_d

    # Key = Inquiry-ID
    @summaries = Hash.new { |h, k| h[k] = Summary.new(k, 0.to_d, []) }
    @villas    = Hash.new { |h, k| h[k] = Set.new }
    @boats     = Hash.new { |h, k| h[k] = Set.new }
  end

  # taxes wird ignoriert, wenn rentable eine Villa ist (nur bei Booten relevant)
  # Siehe https://git.digineo.de/intervillas/support/issues/72#note_3446
  def add(inquiry, billing)
    billing.billables.each do |bb|
      rentable = bb.rentable
      @summaries[inquiry].rentables << rentable
      case rentable
      when Villa then @villas[inquiry] << rentable
      when Boat  then @boats[inquiry]  << rentable
      else raise ArgumentError, "unexpected rentable, got #{rentable.class}"
      end
    end

    billing.payout_for_report.tap { |po|
      @summaries[inquiry].payout += po
      @total_payout              += po
    }
  end

  def each_summary
    @summaries.sort_by { |inquiry, _| inquiry.id }.each do |inquiry, sum|
      yield inquiry, sum.payout, sum.rentables
    end
  end
end
