module Boats::Price
  extend ActiveSupport::Concern

  included do
    has_many :prices,
      class_name: "BoatPrice"

    has_many :prices_eur, -> { where(currency: Currency::EUR) },
      class_name: "BoatPrice"

    has_many :prices_usd, -> { where(currency: Currency::USD) },
      class_name: "BoatPrice"

    has_many :holiday_discounts

    accepts_nested_attributes_for :holiday_discounts,
      allow_destroy: true
  end

  def available_currencies
    Currency::CURRENCIES
  end

  # PERF: Expensive and local memoization is not desired. Cache result
  # on call-site, if possible.
  def boat_price(currency = Currency.current, valid_at: Time.current)
    MonetaryWrapper.new(self, target_currency: currency, valid_at:)
  end

  # PERF: use #boat_price and cache that result
  def deposit(valid_at: Time.current)
    boat_price(valid_at:).deposit
  end

  # PERF: use #boat_price and cache that result
  def training(valid_at: Time.current)
    boat_price(valid_at:).training
  end

  # PERF: use #boat_price and cache that result
  def daily_prices(valid_at: Time.current)
    boat_price(valid_at:).daily
  end

  def teaser_price
    boat_price.daily.first
  end

  # Name intends to be consistent with VillaPrice::MonetaryWrapper, but unlike
  # that, we take a Boat and collect a plethora of BoatPrice instances, hence
  # this is not BoatPrice::MonetaryWrapper.
  class MonetaryWrapper
    # @attr_reader [Hash{:deposit, :training, Integer => Currency::Value}]
    #   Numeric keys mean daily prices.
    attr_reader :prices

    # @attr_reader [Currency::EUR, Currency::USD]
    attr_reader :target_currency

    # @attr_reader [Boat]
    attr_reader :boat

    def initialize(boat, target_currency:, valid_at: Time.current)
      @boat            = boat
      @target_currency = target_currency

      # important: keep `order by amound desc` for #daily_price to work
      @prices = boat.prices.valid_at(valid_at).reorder(amount: :desc).each_with_object({}) do |bp, memo|
        key = bp.subject == "daily" ? bp.amount : bp.subject.to_sym
        if bp.currency == target_currency
          memo[key] = bp
        else
          memo[key] ||= bp
        end
      end

      @prices.transform_values! { |price|
        Currency::Value.new(price.value, price.currency).convert(target_currency)
      }
    end

    def deposit
      @deposit ||= prices.fetch(:deposit) {
        Currency::Value.new(nil, target_currency)
      }
    end

    def training
      @training ||= prices.fetch(:training) {
        Currency::Value.new(nil, target_currency)
      }
    end

    def daily
      @daily ||= prices.select { |k, _| k.is_a? Integer }
    end

    # @param [Integer] number of days to book the boat
    # @return [Currency::Value] price per day
    def daily_price(days_wanted)
      # this assumes #daily (and hence #prices) is sorted
      price = daily.find { |days, _| days <= days_wanted } \
        || daily.to_a.last \
        || [Currency::Value.new(nil, target_currency)]

      price.last
    end
  end

  # Mass-updates boat prices (and holiday_discounts) for a given boat.
  class PriceUpdater
    attr_reader :boat, :errors

    def initialize(boat)
      @boat   = boat
      @errors = nil
    end

    # @param [ActionController::Parameters] params - shape:
    #
    #     params: {
    #       prices: [
    #         { id: 1,        subject: "daily",    currency: "EUR", value: "250", amount: 3 },
    #         { id: 2,        subject: "daily",    currency: "USD", value: "300", amount: 3 },
    #         { id: 3,        subject: "daily",    currency: "EUR", value: "250", amount: 4 },
    #         { id: 4,        subject: "daily",    currency: "EUR", value: "250", amount: 5, _destroy: true },
    #         { id: 16780203, subject: "daily",    currency: "EUR", value: "200", amount: 6 },
    #         { id: 5,        subject: "deposit",  currency: "EUR", value: "1000" },
    #         { id: 6,        subject: "training", currency: "EUR", value: "150"  },
    #         { id: 7,        subject: "training", currency: "USD", value: "180"  },
    #       ],
    #       holiday_discounts: [
    #         { id: 21, description: "christmas", percent => 20, days_before => 1, days_after => 15 },
    #         { id: 23, description: "easter",    percent => 20, days_before => 3, days_after => 7 },
    #       ]
    #     }
    def update(params)
      prices = params[:prices].each_with_object({}) do |price_params, by_id|
        id        = price_params.delete(:id)
        by_id[id] = price_params
      end

      discounts = params[:holiday_discounts].each_with_object({}) do |discount_params, by_id|
        id        = discount_params.delete(:id)
        by_id[id] = discount_params
      end

      Boat.transaction {
        update_prices(prices)
        update_discounts(discounts)
      }
    end

    private

    def update_prices(params)
      prices = boat.prices.valid_now.index_by(&:id)

      params.each do |id, price_params|
        price = prices[id]

        if price && price_params[:_destroy]
          price.destroy! # a before_destroy hook will invalidate price
        elsif price&.value != price_params[:value]
          # To keep historical prices, we don't update existing prices.
          # An after_create hook in BoatPrice will automatically deactivate
          # sibling prices.
          boat.prices.create! price_params.except(:_destroy)
        end
      end
    end

    def update_discounts(params)
      discounts = boat.holiday_discounts.index_by(&:id)

      params.each do |id, discount_params|
        discount = discounts[id]

        if discount && discount_params[:_destroy]
          discount.destroy!
        elsif discount
          discount.update! discount_params.except(:description)
        else
          boat.holiday_discounts.create! discount_params
        end
      end
    end
  end
end
