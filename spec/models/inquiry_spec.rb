require "rails_helper"

RSpec.describe Inquiry do
  it { is_expected.to have_one :villa_inquiry }
  it { is_expected.to have_one :boat_inquiry }
  it { is_expected.to belong_to(:customer).optional }
  it { is_expected.to have_one :booking }
  it { is_expected.to have_many :payments }
  it { is_expected.to have_one :reservation }

  describe ".older_than" do
    before do
      @older ||= create(:inquiry, created_at: 6.days.ago)
      @newer ||= create(:inquiry, created_at: 4.days.ago)
    end

    it "finds inquiries older than 5 days" do
      inquiries = Inquiry.older_than(5.days.ago)
      expect(inquiries).to include(@older)
      expect(inquiries).not_to include(@newer)
    end
  end

  context "without boat" do
    subject(:inquiry) { create_villa_inquiry(villa: villa).inquiry }

    let(:villa) { create :villa, :bookable }

    it "has no boat" do
      expect(villa.boat_possible?).to eq false
    end

    its(:boat_inquiry) { is_expected.to be_nil }
    it { expect_no_clearing_item category: :price, boat_id: kind_of(Integer), on: inquiry }
  end

  describe "factory" do
    subject(:inquiry) { create :inquiry }

    it "is valid" do
      expect(inquiry).to be_valid
    end

    describe ":booked" do
      subject(:inquiry) { create(:inquiry, :booked) }

      it "has booking" do
        expect(inquiry.booking).to be_present
      end
    end
  end
end
