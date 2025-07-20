Currency::Value = Struct.new(:value, :currency, :ceil) do
  include Comparable
  delegate :to_d, :to_f, :to_s, :zero?,
    to: :value

  def initialize(value, *args)
    value = 0 if value.blank?

    super
  end

  # Erstellt Currency::Value-Objekt in Euro über Betrag
  #
  # @param [Numeric] numeric Betrag in Euro
  # @return [Currency::Value]
  def self.euro(numeric)
    new(numeric, Currency::EUR)
  end

  # Wandelt wenn erforderlich den übergebenen Wert in ein
  # Currency::Value-Objekt. Nützlich z.B. bei Summen, deren Rückgabewert 0
  # oder ein Currency::Value sein können.
  def self.make_value(value, currency)
    return Currency::Value.new(value, currency) unless value.is_a? Currency::Value

    value
  end

  # Rechnet einen Betrag in die übergebene Währung um
  #
  # @return [Currency::Value]
  # @param [BigDecimal] in_value Betrag
  # @param [String] currency Währung
  def self.convert(in_value, currency, ceil: true)
    new(in_value, "EUR").convert(currency, ceil: ceil)
  end

  def <=>(other)
    other, = coerce(other) unless other.is_a? Currency::Value
    value <=> other.value
  end

  def *(other)
    make_new(value.*(other.to_d))
  end

  def /(other)
    make_new(value./(other.to_d))
  end

  def -(other)
    raise ArgumentError, "different currencies" if other.respond_to?(:currency) && other.currency != currency

    make_new(value.-(other.to_d))
  end

  def +(other)
    raise ArgumentError, "different currencies" if other.respond_to?(:currency) && other.currency != currency

    make_new(value.+(other.to_d))
  end

  def -@
    make_new(-value)
  end

  def coerce(other)
    [make_new(other), self]
  end

  def round(*args)
    make_new(value.round(*args))
  end

  def ceil!
    make_new(value.ceil)
  end

  def abs
    make_new(value.abs)
  end

  def value
    return self[:value].ceil if ceil

    self[:value]
  end

  def unceiled
    self[:value]
  end

  def unfeed
    unceiled * (1 - (Setting.cc_fee_usd / 100))
  end

  def convert(in_currency, ceil: true, add_cc_fee: true)
    return self if in_currency == currency

    converted = if in_currency == Currency::USD
      tmp  = value * Currency.exchange_rate_for(in_currency)
      tmp *= (1 + (Setting.cc_fee_usd / 100)) if add_cc_fee
      tmp
    elsif in_currency == Currency::EUR
      raise "implement conversion USD to EUR"
    end

    self.class.new(converted, Currency::USD, ceil)
  end

  def as_json(*)
    super(only: %i[value currency])
  end

  private

  def make_new(new_value)
    self.class.new(new_value, currency)
  end
end
