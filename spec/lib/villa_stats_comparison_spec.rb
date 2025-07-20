require "rails_helper"

RSpec.describe VillaStatsComparison do
  subject(:comparison) { VillaStatsComparison.new(villa, 2019) }

  let(:villa) { create :villa }

  before do
    comparison.query
  end

  describe "#each" do
    it {
      expect { |b| comparison.each(&b) }.to(
        yield_successive_args(
          *12.times.map do |n|
            have_attributes(number: n + 1)
          end,
        ),
      )
    }
  end

  describe "#months.first" do
    subject(:month) { comparison.months.first }

    it { expect(month).to have_attributes(number: 1) }

    context "with bookings" do
      let(:villa) { create :villa, :bookable }

      before do
        create_full_booking villa: villa, start_date: Date.new(2018, 1, 1)
        create_full_booking villa: villa, start_date: Date.new(2019, 1, 1), end_date: Date.new(2019, 1, 15)
        create :villa_inquiry, villa: villa, start_date: Date.new(2019, 1, 1)
        create :inquiry, :with_villa_inquiry, villa: villa, start_date: Date.new(2019, 1, 1), admin_submitted: true
        comparison.query
      end

      describe "#inquiries" do
        subject(:inquiries) { month.fetch(:inquiries) }

        it { expect(inquiries.prev_year).to eq 1 }
        it { expect(inquiries.year).to eq 3 }
        it { expect(inquiries.change).to eq 2 }
      end

      describe "#admin_inquiries" do
        subject(:admin_inquiries) { month.fetch(:admin_inquiries) }

        it { expect(admin_inquiries.prev_year).to eq 0 }
        it { expect(admin_inquiries.year).to eq 1 }
        it { expect(admin_inquiries.change).to eq 1 }
      end

      describe "#bookings" do
        subject(:bookings) { month.fetch(:bookings) }

        it { expect(bookings.prev_year).to eq 1 }
        it { expect(bookings.year).to eq 1 }
        it { expect(bookings.change).to eq 0 }
      end

      describe "#utilization" do
        subject(:utilization) { month.fetch(:utilization) }

        it { expect(utilization.prev_year).to eq 23 }
        it { expect(utilization.year).to eq 45 }
        it { expect(utilization.change).to eq 22 }
      end
    end
  end
end
