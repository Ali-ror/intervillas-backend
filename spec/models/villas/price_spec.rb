require "rails_helper"

RSpec.describe Villa do # rubocop:disable RSpec/FilePath
  it { is_expected.to have_one :villa_price_eur }
  it { is_expected.to have_one :villa_price_usd }
  it { is_expected.to have_many :villa_prices }

  describe "currency conversion" do
    subject(:villa_price) { villa.villa_price }

    let(:villa)         { create :villa }
    let(:exchange_rate) { 1.2 } # EUR to USD
    let(:cc_fee)        { 10.0 } # percentage points

    let(:currencies) { [Currency::EUR] }
    let(:values) {
      {
        base_rate:         100,
        additional_adult:  45,
        children_under_12: 35,
        children_under_6:  30,
        cleaning:          200,
        deposit:           1000,
      }
    }

    shared_examples "a currency converter" do |from:, to:, scale: 1|
      its(:currency)          { is_expected.to eq from }
      its(:target_currency)   { is_expected.to eq to }
      its(:base_rate)         { is_expected.to be_currency_value(100 * scale.to_d, to) }
      its(:additional_adult)  { is_expected.to be_currency_value(45 * scale.to_d, to) }
      its(:children_under_12) { is_expected.to be_currency_value(35 * scale.to_d, to) }
      its(:children_under_6)  { is_expected.to be_currency_value(30 * scale.to_d, to) }
      its(:cleaning)          { is_expected.to be_currency_value(200 * scale.to_d, to) }
      its(:deposit)           { is_expected.to be_currency_value(1000 * scale.to_d, to) }
    end

    before do
      Setting.exchange_rate_usd = exchange_rate
      Setting.cc_fee_usd        = cc_fee

      currencies.each do |cur|
        create(:villa_price, villa: villa, **values, currency: cur)
      end
    end

    # ceil=nil means "don't care", otherwise use true/false
    matcher :be_currency_value do |value, currency, ceil = nil|
      match do |actual|
        actual.is_a?(Currency::Value)              &&
          actual[:value]    == expected[:value]    &&
          actual[:currency] == expected[:currency] &&
          (ceil.nil? || actual.ceil == expected.ceil)
      end

      description do
        lparen, rparen = ceil ? ["⌈", "⌉"] : ["(", ")"]
        "eq Currency#{lparen}#{currency} #{value}#{rparen}"
      end

      failure_message do |actual|
        <<~MSG
          expected: #{actual.inspect}
               got: #{expected.inspect}
        MSG
      end

      define_method :expected do
        @expected ||= Currency::Value.new(value, currency, ceil)
      end
    end

    context "prices in EUR" do
      describe "requesting in EUR" do
        before { Currency.current = Currency::EUR }

        include_examples "a currency converter",
          from: Currency::EUR,
          to:   Currency::EUR
      end

      context "requesting in USD" do
        before { Currency.current = Currency::USD }

        # the scaling factor is 1.2 (=exchange_rate) * 1.1 (= cc_fee)
        include_examples "a currency converter",
          from:  Currency::EUR,
          to:    Currency::USD,
          scale: 1.32
      end
    end

    context "prices in EUR and USD" do
      let(:currencies) { [Currency::EUR, Currency::USD] }

      describe "requesting in EUR" do
        before { Currency.current = Currency::EUR }

        include_examples "a currency converter",
          from: Currency::EUR,
          to:   Currency::EUR
      end

      describe "requesting in USD" do
        before { Currency.current = Currency::USD }

        include_examples "a currency converter",
          from: Currency::USD,
          to:   Currency::USD
      end
    end

    context "prices in USD-only" do
      let(:currencies) { [Currency::USD] }

      describe "requesting in EUR" do
        before { Currency.current = Currency::EUR }

        # this might look surprising, but when only USD prices are available,
        # the customer should always receive USD prices, even if they select
        # a different currency
        include_examples "a currency converter",
          from: Currency::USD,
          to:   Currency::USD
      end

      describe "requesting in USD" do
        before { Currency.current = Currency::USD }

        include_examples "a currency converter",
          from: Currency::USD,
          to:   Currency::USD
      end
    end
  end
end
