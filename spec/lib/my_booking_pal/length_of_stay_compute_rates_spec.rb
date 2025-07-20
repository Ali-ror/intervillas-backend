require "rails_helper"

RSpec.describe MyBookingPal::LengthOfStay, "#compute_rates" do
  subject(:los) { described_class.new(product, lead_time:, compute_limit:) }

  # constructor arguments
  let(:product)       { double("MyBookingPal::Product", villa:) } # rubocop:disable RSpec/VerifiedDoubles
  let(:lead_time)     { 2.days }
  let(:compute_limit) { 2.months }

  let(:villa) do
    create :villa, :bookable, additional_properties: {
      los: { max_stay:, advance_months:, surcharge: },
    }
  end

  # additional properties
  let(:max_stay)       { 18 } # in days, should be > minimum_booking_days on christmas
  let(:advance_months) { 1 }  # in months, should at least be 1
  let(:surcharge)      { 0 }  # percentage points

  # Fetches the computed rates from the test subject, and compares them with
  # a test fixture. The `los_args` are forwarded to `subject.compute_rates`.
  #
  # For the comparison, the rates are converted into a tabular text form. This
  # format is intendet for easy human digestion. Rates are grouped by the number
  # and sorted by date. The fields in each row are separated with a tab character,
  # setting the editor tab width to 8 is beneficial.
  #
  # This helper will also write fixture files, if ENV["WRITE_FIXTURES"] is set.
  def expect_rates_to_match_fixture(fixture_name, **los_args) # rubocop:disable Metrics/CyclomaticComplexity
    expected = los.compute_rates(**los_args).group_by(&:num_adults).each_with_object([]) { |(num_adults, rates), list|
      list << "" if list.size > 0
      list << "# rates for #{num_adults} people" << ""

      rates.sort_by(&:date).each do |r|
        row = format "%<date>s\t%-<cat>8s\t%<rates>s",
          date:  r.date.strftime("%Y-%m-%d"),
          cat:   r.category,
          rates: (r.rates.empty? ? "-" : r.rates.join("\t"))
        list.push(row)
      end
    }.push("").join("\n")

    fixture = Rails.root.join("spec/fixtures/my_booking_pal/#{fixture_name}.los")
    fixture.open("w") { _1.write expected } if ENV["WRITE_FIXTURES"]

    expect(fixture.read).to eq(expected)
  end

  it "without params" do
    travel_to "2024-03-28".to_date do
      # same as "with fixed start date"
      expect_rates_to_match_fixture "simple"
    end
  end

  it "with fixed start date" do
    # same as "without params"
    expect_rates_to_match_fixture "simple", start_date: "2024-03-28".to_date
  end

  it "over christmas" do
    travel_to "2024-12-18".to_date do
      expect_rates_to_match_fixture "christmas"
    end
  end

  context "with occupied ranges" do
    let(:ref_date) { "2024-08-10".to_date }

    before { travel_to "2024-08-01T12:34:56Z" }

    def create_blocking(start_date, duration)
      create :blocking, villa:, start_date:, end_date: start_date + duration
    end

    it "at the start" do
      create_blocking(ref_date - 4.days, 8.days)
      expect_rates_to_match_fixture "blocked_begin", start_date: ref_date
    end

    it "at the end" do
      create_blocking(ref_date, 8.days)
      expect_rates_to_match_fixture "blocked_end", start_date: ref_date - advance_months.months
    end

    it "after the end" do
      create_blocking(ref_date + 9.days, 8.days)
      expect_rates_to_match_fixture "blocked_after", start_date: ref_date - advance_months.months
    end

    it "in the middle" do
      create_blocking(ref_date - 4.days, 2.days)
      create_blocking(ref_date + 8.days, 2.days)
      expect_rates_to_match_fixture "blocked_middle", start_date: ref_date - 1.month
    end

    it "the whole block" do
      create_blocking(ref_date - 2.months, 4.months)
      expect_rates_to_match_fixture "blocked_whole", start_date: ref_date - 1.month
    end
  end

  it "with overlapping high season" do
    create :high_season,
      villas:    [villa],
      starts_on: "2023-12-15".to_date,
      ends_on:   "2024-06-01".to_date

    expect_rates_to_match_fixture "high_season", start_date: "2024-05-15".to_date
  end

  context "with commission surcharge" do
    let(:surcharge) { 50 }

    it "inflates prices" do
      expect_rates_to_match_fixture "simple+surcharge", start_date: "2024-03-28".to_date
    end

    it "and high season" do
      create :high_season,
        villas:    [villa],
        starts_on: "2023-12-15".to_date,
        ends_on:   "2024-06-01".to_date

      expect_rates_to_match_fixture "high_season+surcharge", start_date: "2024-05-15".to_date
    end
  end

  context "with weekly prices" do
    def create_prices(currency, base_rate)
      create(:villa_price, villa:, currency:, weekly: true, base_rate:)
    end

    before { villa.villa_prices.destroy_all }

    it "in EUR" do
      # los_rate == ceil(base_rate + currency conversion + credit card fees),
      # so ceil(€250 * 1.282 $/€ * 1.035) = $332.
      create_prices(Currency::EUR, 250)

      expect_rates_to_match_fixture "simple+weekly", start_date: "2024-03-28".to_date
    end

    it "in USD" do
      # for USD prices, the base_rate is used as-is
      create_prices(Currency::USD, 300)

      expect_rates_to_match_fixture "simple+weekly+usd", start_date: "2024-03-28".to_date
    end

    it "in USD and EUR" do
      create_prices(Currency::EUR, 250)
      create_prices(Currency::USD, 300)

      # USD prices are preferred, so same fixture
      expect_rates_to_match_fixture "simple+weekly+usd", start_date: "2024-03-28".to_date
    end
  end
end
