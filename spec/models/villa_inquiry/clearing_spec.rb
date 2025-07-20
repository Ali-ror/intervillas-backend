require "rails_helper"

RSpec.describe VillaInquiry do
  subject(:villa_inquiry) { create :villa_inquiry, villa: villa }

  let(:villa) { create :villa, :bookable }

  describe "#create_clearing_items" do
    it { expect_clearing_item(category: "base_rate", amount: 1, price: 160.to_d, on: villa_inquiry) }
    it { expect_clearing_item(category: "deposit", amount: 1, price: 42.42.to_d, on: villa_inquiry) }
    it { expect_clearing_item(category: "cleaning", amount: 1, price: 42.42.to_d, on: villa_inquiry) }
    it { expect_no_clearing_item(category: "children_under_6", on: villa_inquiry) }
    it { expect_no_clearing_item(category: "children_under_12", on: villa_inquiry) }
  end
end
