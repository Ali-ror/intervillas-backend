require "rails_helper"

class NightsCalculatorStub
  include NightsCalculator
end

RSpec.describe NightsCalculator do
  it "defines minimum number of bookable nights" do
    expect(described_class::MINIMUM_BOOKING_NIGHTS).to be_kind_of(Integer)
  end

  it "defines an absolute minimum number of bookable days" do
    expect(described_class::ABSOLUTE_MINIMUM_DAYS).to be_kind_of(Integer)
  end

  it "has semantically and logically minima defined" do
    expect(described_class::MINIMUM_BOOKING_NIGHTS).to(
      be >= described_class::ABSOLUTE_MINIMUM_DAYS + 2,
    )
  end

  describe "::minimum_booking_nights" do
    subject { NightsCalculatorStub.minimum_booking_nights(start_date, end_date, special: special, villa: villa) }

    # ein Datum, das garantiert nicht mit Weihnachten oder Ostern in Berührung kommt
    let(:start_date) { Date.new 2016, 7, 6 }
    let(:end_date)   { nil }
    let(:special)    { false }
    let(:villa)      { nil }

    it { is_expected.to eq 7 }

    context "special given" do
      let(:special) { true }

      it { is_expected.to eq 3 }
    end

    context "villa with minimum_booking_nights" do
      let(:villa) { instance_double(Villa, minimum_booking_nights: 9) }

      it {
        is_expected.to eq 9
        expect(villa).to have_received :minimum_booking_nights
      }
    end

    context "christmas season" do
      # bis 15.12. = 7 Tage
      # 16.-26.12. = 14 Tage
      # ab 27.12.  = 7 Tage

      context "before/after christmas" do
        [14, 15, 27, 28].each do |d|
          it "does leave the duration at 7 days on Year/12/#{d}" do
            start = Date.current.change(month: 12, day: d)
            expect(NightsCalculatorStub.minimum_booking_nights(start)).to eq 7
          end
        end
      end

      context "overlapping christmas" do
        (16..26).each do |d|
          it "extends the duration to 14 days on Year/12/#{d}" do
            start = Date.current.change(month: 12, day: d)
            expect(NightsCalculatorStub.minimum_booking_nights(start)).to eq 14
          end
        end

        context "with villa.minimum_booking_nights > 14" do
          let(:start_date) { Date.current.change(month: 12, day: 20) }
          let(:villa)      { instance_double(Villa, minimum_booking_nights: 28) }

          it {
            is_expected.to eq 28
            expect(villa).to have_received :minimum_booking_nights
          }
        end
      end
    end
  end
end
