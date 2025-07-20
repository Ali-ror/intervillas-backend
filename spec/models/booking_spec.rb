require "rails_helper"

RSpec.describe Booking do
  subject { build(:booking_minimal, state: "booked") }

  it { is_expected.to belong_to :inquiry }
  it { is_expected.to have_one :villa }

  it { is_expected.to have_many :travelers }

  describe "#gap_after" do
    subject { villa.gap_after(today) }

    include_context "gap"

    before do
      min = NightsCalculator::MINIMUM_BOOKING_NIGHTS.days
      create_full_booking \
        villa:      villa,
        start_date: today - min,
        end_date:   today
      create_full_booking \
        villa:      villa,
        start_date: today + gap,
        end_date:   today + gap + min
    end

    context "1 day apart" do
      let(:gap) { 1.day }

      it { is_expected.to be NightsCalculator::ABSOLUTE_MINIMUM_DAYS }
    end

    [1, 0].each do |i|
      context "ABSOLUTE_MINIMUM_DAYS - #{i} days apart" do
        let(:gap) { (NightsCalculator::ABSOLUTE_MINIMUM_DAYS - i).days }

        it { is_expected.to eq NightsCalculator::ABSOLUTE_MINIMUM_DAYS }
      end
    end

    [1, 0].each do |i|
      context "MINIMUM_BOOKING_NIGHTS - #{i} days apart" do
        let(:gap) { (NightsCalculator::MINIMUM_BOOKING_NIGHTS - i).days }

        it { is_expected.to eq NightsCalculator::MINIMUM_BOOKING_NIGHTS - i }
      end
    end

    context "MINIMUM_BOOKING_NIGHTS + 1 days apart" do
      let(:gap) { (NightsCalculator::MINIMUM_BOOKING_NIGHTS + 1).days }

      it { is_expected.to eq NightsCalculator::MINIMUM_BOOKING_NIGHTS }
    end

    context "with villa.minimum_booking_nights > 7" do
      before { villa.update minimum_booking_nights: 28 }

      it { is_expected.to eq gap }

      context "and bookings 10d apart" do
        let(:gap) { 10 }

        it { is_expected.to eq gap }
      end

      context "and bookings 30d apart" do
        let(:gap) { 30 }

        it { is_expected.to eq villa.minimum_booking_nights }
      end
    end
  end

  context "CSV export" do
    subject(:csv) { booking.to_comma }

    let(:booking) { create_full_booking }
    let(:exports) {
      %i[
        number start_date end_date villa name csv_state adults
        children_under_12 children_under_6 csv_boat_state
      ]
    }

    it "has headers" do
      expect(booking.to_comma_headers.size).to be exports.size
    end

    it "is exportable" do
      expected_values = exports.map { |f| booking.send(f).to_s }
      is_expected.to eq expected_values
    end
  end
end
