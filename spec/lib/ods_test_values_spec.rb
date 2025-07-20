require "rails_helper"

RSpec.describe OdsTestValues do
  subject(:curr_values) { OdsTestValues.for(Currency::EUR) }

  describe "#symbol" do
    it { expect(curr_values.symbol).to eq "€" }
  end
end
