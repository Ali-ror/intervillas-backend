require "rails_helper"

RSpec.describe BoatInquiry do
  let(:boat_clearing) { boat_inquiry.clearing }

  it { is_expected.to belong_to :boat }
  it { is_expected.to belong_to :inquiry }
  it { is_expected.to have_one :villa_inquiry }
  it { is_expected.to have_one :villa }

  describe "mandatory boat" do
    subject(:boat_inquiry) { create :boat_inquiry, :mandatory }

    delegate :inquiry, to: :boat_inquiry

    its(:villa) do
      is_expected.to be_boat_inclusive
    end

    its(:boat_state) { is_expected.to eq "free" }
    it { expect_no_clearing_item(category: :price, on: boat_inquiry) }
    it { expect(boat_clearing.total_rents).to eq 0 }
    it { expect(boat_clearing.total_deposit).to eq 900 }
    it { expect_clearing_item(category: "deposit", price: 900, on: boat_inquiry) }

    it "calculates the total price with boat" do
      expect(inquiry.clearing.sub_total).to eq 1472.42.to_d
    end
  end

  describe "optional boat" do
    subject(:boat_inquiry) { create :boat_inquiry } # :optional ist default

    its(:villa) do
      is_expected.to be_boat_optional
    end

    its(:boat_state) { is_expected.to eq "charged" }
    it { expect_no_clearing_item(category: :price, price: 23.23, on: boat_inquiry) }
    its(:boat_days) { is_expected.to eq 7 }
    it { expect(boat_clearing.total_rents).to eq 162.61 } # boat_price * boat_days
    it { expect(boat_clearing.total_deposit).to eq 900 }

    describe "booking a boat" do
      it { is_expected.to be_still_available }

      context "with blocking" do
        before do
          create :blocking,
            boat:       boat_inquiry.boat,
            start_date: boat_inquiry.start_date - 1.week,
            end_date:   boat_inquiry.end_date + 1.week
        end

        it { is_expected.not_to be_still_available }
      end
    end
  end

  describe "factory" do
    describe ":booked" do
      subject(:boat_inquiry) { create(:boat_inquiry, :booked) }

      it "has booking" do
        expect(boat_inquiry.booking).to be_present
      end
    end
  end
end
