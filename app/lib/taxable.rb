#
# Weil ich mir das nie merken kann:
#
#   gross = Brutto (inkl. Steuern)
#   net   = Netto  (vor Steuern)
#
module Taxable
  extend self

  UnknownTaxId = Class.new NameError

  KNOWN_TAXES = {
    sales_2019:    0.065.to_d,
    tourist:       0.05.to_d,
    cleaning_2019: 0.115.to_d,
    energy_2019:   0.115.to_d,

    # warning: use this tax rates only for Billings with date < 2019-01-01
    sales:         0.06.to_d,
    energy:        0.11.to_d,
    cleaning:      0.11.to_d,
  }.with_indifferent_access.freeze

  # Brutto zu Netto
  def to_net(gross_val, tax)
    gross_val / to_tax_factor(tax)
  end

  # Netto zu Brutto
  def to_gross(net_val, tax)
    net_val * to_tax_factor(tax)
  end

  # Steueranteil
  def tax(net_val, tax)
    to_gross(net_val, tax) - net_val
  end

  # Liefert den Steuerfaktor zu einer Steuer (val = String oder Symbol) oder
  # zu einem Steuersatz (val = Numeric).
  #
  #     Taxable.to_tax_factor(:sales)  #=> 1 + KNOWN_TAXES[:sales]
  #     Taxable.to_tax_factor(0.05)    #=> 1.05
  #     Taxable.to_tax_factor(11)      #=> 1.11
  #
  # Bei Werten aus {1.0, ..., 2.0} wird angenommen, dass es sich schon um einen
  # Steuerfaktor handelt.
  def to_tax_factor(val)
    case val
    when Symbol, String
      1 + find_tax(val)
    when (0.0..1.0)
      1 + val
    when (1.0..2.0)
      warn "assuming tax factor already calculated for #{val}"
      val
    else
      1 + (val / 100.0)
    end
  end

  def find_tax(name)
    KNOWN_TAXES.fetch name do
      raise UnknownTaxId, "unknwon tax: #{name}"
    end
  end

  def find_taxes(*names)
    # KNOWN_TAXES.slice(*names) liefert keinen Fehler bei unbekannten Keys
    # (wir wollen den aber provozieren)
    names.map { |n|
      tax_value = find_tax(n)
      [n.to_sym, tax_value]
    }.to_h
  end
end
