require "rails_helper"

RSpec.describe BoatInquiry do
  subject(:boat_inquiry) { create_boat_inquiry }

  describe "#create_clearing_items" do
    it { expect_clearing_item(category: "deposit", price: 900, on: boat_inquiry) }
    it { expect_clearing_item(category: "training", price: 150, on: boat_inquiry) }
  end
end
