require "rails_helper"

RSpec.describe MyBookingPal::LengthOfStay::DiffChunker do
  subject(:chunker) do
    described_class.new(product).tap { |instance|
      los_rates = los.compute_rates(start_date: fixture_date)

      allow(instance).to receive(:los_rates).and_return(los_rates)
    }
  end

  let(:los) do
    MyBookingPal::LengthOfStay.new product,
      lead_time:     2.days,
      compute_limit: 2.months
  end

  let(:product) do
    double "MyBookingPal::Product", # rubocop:disable RSpec/VerifiedDoubles
      foreign_id:    123_456_789_012,
      villa:         villa,
      remote_prices: remote_prices
  end

  let(:villa) do
    create :villa, :bookable, additional_properties: {
      los: {
        max_stay:       18,
        advance_months: 1,
        surcharge:      0,
      },
    }
  end

  let(:fixture_name) { "simple" }
  let(:fixture)      { Rails.root.join("spec/fixtures/my_booking_pal/#{fixture_name}.los") }
  let(:fixture_date) { remote_prices.map(&:date).min }

  # NOTE: Product#remote_prices usually invokes the API client. We'll skip that
  # and parse the fixture file into an array of MyBookingPal::LengthOfStay::Rate
  # (which is what Product#remote_prices ultimately does as well).
  let(:remote_prices) do
    curr_people = nil
    prices      = []

    fixture.each_line do |line|
      case line
      when /^# rates for (\d) people/
        curr_people = Regexp.last_match(1).to_i
      when /^\d{4}-\d\d-\d\d\t/
        date, _cat, *rates = line.chomp.split("\t")

        rates.map! { |r| r == "-" ? 0.0 : Float(r) }
        rates.pop while rates[-1]&.zero?

        prices << MyBookingPal::LengthOfStay::Rate.new(date.to_date, curr_people, rates, nil)
      end
    end

    prices
  end

  before do
    travel_to fixture_date + 2.hours + 11.minutes
  end

  it "does not yield, when there are no changes" do
    expect { |b| chunker.each(&b) }.not_to yield_control
  end

  context "on rollover" do
    before do
      # massage data: remote_prices appear as if they were created yesterday
      remote_prices.map! { |rate|
        rate.date -= 1.day
        rate
      }
    end

    it "yields a small change" do
      change = {
        data: {
          productId: product.foreign_id,
          losRates:  [
            # dates < lead_time.from_now are cleared
            *[2, 3, 4].map { |ppl|
              { checkInDate: "2024-03-29", maxGuests: ppl, losValue: [0] }
            },
            # max_stay.days_from now differs
            *{ 2 => 213, 3 => 267, 4 => 321 }.map { |ppl, daily|
              v = [0, 0, 0, 0, 0, 0, *(7..18).map { daily * _1 }]
              { checkInDate: "2024-05-05", maxGuests: ppl, losValue: v }
            },
            # yesterday's compute_limit is one day before today's one
            *[2, 3, 4].map { |ppl|
              { checkInDate: "2024-05-28", maxGuests: ppl, losValue: [0] }
            },
          ],
        },
      }.to_json

      expect { |b| chunker.each(&b) }.to yield_successive_args(change)
    end
  end
end
