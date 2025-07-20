require "rails_helper"

RSpec.describe Rentable do
  describe "#utilization" do
    subject(:villa) { create :villa, :bookable }

    let(:year) { 2016 }

    before do
      create :booking, villa: villa, start_date: "#{year}-06-03".to_date
      create :booking, villa: villa, start_date: "#{year - 1}-12-30".to_date
    end

    it { expect(villa.utilization_in_year(year)).to eq 4 }
  end
end
