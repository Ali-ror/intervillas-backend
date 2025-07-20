require "rails_helper"

RSpec.describe MyBookingPal::LengthOfStay::ImportantDates do
  subject(:important_dates) {
    # class is semi-private, hence no kwargs
    described_class.new(start_date, end_date, lead_time, compute_limit, &minimum_booking_days)
  }

  let(:start_date)    { "2024-08-01" } # string, constructor shall call #to_date
  let(:end_date)      { "2024-12-31".to_date }
  let(:lead_time)     { 7.days }
  let(:compute_limit) { 12.months }

  let(:minimum_booking_days) do
    # in reality, an arrival just before christmas would bump the min booking days from 7 to 14 days
    proc { |latest_arrival| latest_arrival.month.even? ? 5.days : 10.days }
  end

  its(:start_date)       { is_expected.to eq "2024-08-01".to_date }
  its(:end_date)         { is_expected.to eq "2024-12-31".to_date }
  its(:earliest_arrival) { is_expected.to eq "2024-08-08".to_date } # start + lead
  its(:latest_departure) { is_expected.to eq "2025-01-05".to_date } # end + min booking days (5)
  its(:latest_arrival)   { is_expected.to eq "2024-12-31".to_date } # same as end date
  its(:max_compute_date) { is_expected.to eq "2025-08-01".to_date } # start + compute limit

  context "shifted" do
    let(:end_date) { "2024-11-30" }

    its(:start_date)       { is_expected.to eq "2024-08-01".to_date } # unchanged
    its(:end_date)         { is_expected.to eq "2024-11-30".to_date }
    its(:earliest_arrival) { is_expected.to eq "2024-08-08".to_date } # unchanged
    its(:latest_departure) { is_expected.to eq "2024-12-10".to_date } # end + min booking days (10)
    its(:latest_arrival)   { is_expected.to eq "2024-11-30".to_date } # still same as end date
    its(:max_compute_date) { is_expected.to eq "2025-08-01".to_date } # unchanged
  end

  # this really is an edge case, but if this fails, a lot of other spec might fail as well
  context "latest arrival trumps compute limit" do
    let(:compute_limit)        { 1.month }
    let(:minimum_booking_days) { proc { 60.days } }

    its(:max_compute_date) { is_expected.to eq "2025-03-01".to_date } # end + min booking days
  end

  it "#collect_rates collects rates" do
    i = -1

    actual = important_dates.collect_rates { |date|
      expect(date).to be_kind_of Date
      [i += 1]
    }

    expect(actual).to be_kind_of Array # 0..365
    expect(actual[0]).to eq 0
    expect(actual[-1]).to eq ("2025-08-01".to_date - "2024-08-01".to_date).to_i
  end
end
