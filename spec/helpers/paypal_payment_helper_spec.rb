require "rails_helper"

def switch_to_dollar(ex)
  c                = Currency.current
  Currency.current = Currency::USD
  ex.run
  Currency.current = c
end

# Specs in this file have access to a helper object that includes
# the PaypalPaymentHelperHelper. For example:
#
# describe PaypalPaymentHelperHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe PaypalPaymentHelper do
  describe "#bsp1_fees" do
    context "EUR" do
      it "includes EUR fees" do
        expect(helper.bsp1_fees).to eq "2,9% + € 0,09"
      end
    end

    context "USD" do
      around(&method(:switch_to_dollar))

      it "includes USD fees" do
        expect(helper.bsp1_fees).to eq "2,9% + $ 0,00"
      end
    end
  end

  describe "#paypal_fees" do
    context "EUR" do
      it "includes EUR fees" do
        expect(helper.paypal_fees).to eq "3,4% + € 0,35"
      end
    end
  end
end
