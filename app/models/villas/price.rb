module Villas::Price
  extend ActiveSupport::Concern

  included do
    has_many :villa_prices

    has_one :villa_price_eur, -> { where(currency: Currency::EUR) },
      class_name: "VillaPrice"

    has_one :villa_price_usd, -> { where(currency: Currency::USD) },
      class_name: "VillaPrice"

    has_many :holiday_discounts

    accepts_nested_attributes_for :holiday_discounts,
      allow_destroy: true

    accepts_nested_attributes_for :villa_price_eur, :villa_price_usd,
      allow_destroy: true,
      update_only:   true

    delegate :traveler_price_categories,
      to:        :villa_price,
      allow_nil: true
  end

  def available_currencies
    villa_prices.pluck(:currency)
  end

  def villa_price(currency = Currency.current)
    # NOTE: for new villas (and old, inactive villas), neither of
    #       villa_price_{eur,usd} are present

    # customer wants USD prices, and we have USD prices
    return villa_price_usd.to_monetary if currency == Currency::USD && villa_price_usd

    # customer wants EUR prices, but villa is only available in USD
    return villa_price_usd&.to_monetary if currency == Currency::EUR && !villa_price_eur

    # default: convert EUR prices into whatever customer wants
    villa_price_eur&.to_monetary currency
  end

  def traveler_price_categories_for_currency(currency)
    villa_price(currency).traveler_price_categories
  end

  def teaser_price
    if (base_rate = villa_price&.base_rate)
      base_rate * 7
    else
      Currency::Value.new 0, Currency.current
    end
  end

  def max_people
    beds_count
  end
end
