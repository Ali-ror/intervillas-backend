require "rails_helper"

RSpec.describe Bsp1PaymentHelper do
  describe "#bsp1_params" do
    subject(:params) do
      helper.bsp1_params(
        amount:       100,
        payment_type: "cc",
        reference:    "1",
        currency:     Currency::EUR,
      )
    end

    it "berechnet hash" do
      expect(params[:hash]).to(
        eq("5333d5229fc8fc0a0709c61d31280508427a0440b253ae539dd4df899940e24826fca0b52bdb144eaef77d54741639c4"),
      )
    end

    it "includes test mode" do
      expect(params[:mode]).to eq "test"
    end
  end
end
