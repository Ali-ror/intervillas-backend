require "rails_helper"

RSpec.describe VillaPrice do
  it { is_expected.to belong_to :villa }

  context "monetary wrapper" do
    subject(:wrapper) { build(:villa_price).to_monetary }

    it "delivers correct pers_price" do
      expect(wrapper.calculate_base_rate(occupancy: 2, category: :adults)).to eq(160)
      expect(wrapper.calculate_base_rate(occupancy: 15, category: :adults)).to eq(680)
    end

    it "calculates child_price" do
      expect(wrapper.calculate_base_rate(occupancy: 1, category: :children_under_6)).to eq(8)
      expect(wrapper.calculate_base_rate(occupancy: 1, category: :children_under_12)).to eq(18)
    end
  end

  describe "minimum people" do
    subject(:prices) { build(:villa_price, villa: villa, weekly: weekly) }

    let(:villa)  { create(:villa, minimum_people: people) }
    let(:people) { 2 }
    let(:weekly) { false }

    it { expect(prices).to be_valid }

    context "more than 2" do
      let(:people) { 4 }

      it { expect(prices).not_to be_valid }

      it {
        expect(prices.tap(&:validate).errors.details).to match(
          children_under_12: [{ error: :conflicting_minimum_people }],
          children_under_6:  [{ error: :conflicting_minimum_people }],
        )
      }
    end

    context "weekly pricing" do
      let(:people) { 4 }
      let(:weekly) { true }

      it { expect(prices).to be_valid }
    end
  end
end
