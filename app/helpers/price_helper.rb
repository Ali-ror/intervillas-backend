module PriceHelper
  CURRENCY_OPTIONS = {
    Currency::EUR.freeze => { unit: Currency::SYMBOLS.fetch(Currency::EUR) },
    Currency::USD.freeze => { unit: Currency::SYMBOLS.fetch(Currency::USD) },
  }.freeze

  def display_price(num, **opts)
    return "-" if num.nil?

    price_display = number_to_currency num.to_d, CURRENCY_OPTIONS.fetch(num.currency).merge(**opts)
    if block_given?
      yield price_display
      nil # keine Rückgabe, die ins Template geschrieben werden könnte
    else
      price_display
    end
  end

  # @param [String] currency Currency::EUR or Currency::USD
  def currency_symbol(currency)
    Currency::SYMBOLS.fetch(currency)
  end
end
