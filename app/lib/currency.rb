class Currency < ActiveSupport::CurrentAttributes
  Error = Class.new(StandardError)

  EUR = "EUR".freeze
  USD = "USD".freeze

  SYMBOLS = {
    Currency::EUR => "€",
    Currency::USD => "$",
  }.freeze

  CURRENCIES = [EUR, USD].freeze

  attribute :current

  def current
    super || Currency::EUR
  end

  def with(currency)
    currency_was = current
    self.current = currency
    yield
  ensure
    self.current = currency_was
  end

  def reset!
    self.current = nil
  end

  def usd!
    self.current = Currency::USD
  end

  # @return [String]
  def symbol(curr)
    SYMBOLS.fetch(curr)
  end

  def exchange_rate_for(currency)
    case currency
    when Currency::EUR
      "1.0".to_d
    when Currency::USD
      ::Setting.exchange_rate_usd
    else
      raise ArgumentError, "unknown currency: #{currency}"
    end
  end
end
