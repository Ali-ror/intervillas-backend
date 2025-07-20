require "rails_helper"

RSpec.describe BoatBilling do
  subject { inquiry.boat_billings.first }

  include_examples "prepare billings"

  context "model" do
    subject { BoatBilling.new }

    it { is_expected.to have_one :boat }
    it { is_expected.to belong_to(:owner).class_name("Contact") }
  end

  shared_examples "taxed calculations" do |year, values|
    let(:boat_owner)        { villa_owner }
    let(:eps)               { 0.001 }
    let(:commission_factor) { values["commission"] / 100.0 }
    let(:gross_total)       { values["rent.gross"] + values["training.gross"] }

    around do |ex|
      Timecop.travel Date.current.strftime("#{year}-%m-%d").to_date, &ex
    end

    it "calculates rent" do
      rent = subject.rent
      expect(rent).to be_kind_of Billing::Position

      a, b = year < 2019 ? %i[sales sales_2019] : %i[sales_2019 sales]
      expect(rent.gross).to be_within(eps).of values["rent.gross"]
      expect(rent.net).to be_within(eps).of values["rent.net"]
      expect(rent.proportions[a]).to be_within(eps).of values["rent.prop.sales"]
      expect(rent.proportions[b]).to be_nil
    end

    it "calculates training" do
      training = subject.training
      expect(training).to be_kind_of Billing::Position

      a, b = year < 2019 ? %i[sales sales_2019] : %i[sales_2019 sales]
      expect(training.gross).to be_within(eps).of values["training.gross"]
      expect(training.proportions[a]).to be_within(eps).of values["training.prop.sales"]
      expect(training.proportions[b]).to be_nil
    end

    it "calculates positions" do
      pos = subject.positions
      expect(pos).to be_kind_of Array
      expect(pos).to all be_kind_of(Billing::Position)
      expect(pos.map(&:gross).sum).to be_within(eps).of gross_total
    end

    its("total.gross")      { is_expected.to be_within(eps).of gross_total }
    its(:commission)        { is_expected.to eq values["commission"] }
    its(:agency_commission) { is_expected.to be_within(eps).of values["rent.net"] * commission_factor }

    describe "60:40 rule" do
      let(:boat_optional) { false }

      its(:boat_inquiry)      { is_expected.to be_present }
      its("rent.gross")       { is_expected.to be_within(eps).of values["booking.gross"] * 0.4 }
      its("rent.net")         { is_expected.to be_within(eps).of values["booking.net"] * 0.4 }
      its("total.gross")      { is_expected.to be_within(eps).of (values["booking.gross"] * 0.4) + values["training.gross"] }
      its(:agency_commission) { is_expected.to be_within(eps).of values["booking.net"] * 0.4 * commission_factor }
    end
  end

  context "before 2019" do
    include_examples "taxed calculations", 2016,
      "rent.gross"          => 139.38,
      "rent.net"            => 131.49,
      "rent.prop.sales"     => 7.889,
      "training.gross"      => 150,
      "training.prop.sales" => 8.49,
      "commission"          => 20,
      "booking.gross"       => 1120, # clearing.total_rents
      "booking.net"         => 1056.603 # 6 % Sales Tax
  end

  context "after 2019" do
    include_examples "taxed calculations", 2019,
      "rent.gross"          => 139.38,
      "rent.net"            => 130.873,
      "rent.prop.sales"     => 8.506,
      "training.gross"      => 150,
      "training.prop.sales" => 9.154,
      "commission"          => 20,
      "booking.gross"       => 1120, # clearing.total_rents
      "booking.net"         => 1051.64319249 # 6,5 % Sales Tax
  end

  describe "factory" do
    subject(:boat_billing) { create(:boat_billing) }

    it "is valid" do
      expect(boat_billing).to be_valid
    end

    it "is booked by default" do
      expect(boat_billing.booking).to be_present
    end

    describe ":net_owner" do
      subject(:boat_billing) { create(:boat_billing, :net_owner) }

      it "has owner with net flag set" do
        expect(boat_billing.owner.net).to be_truthy
      end
    end
  end
end
