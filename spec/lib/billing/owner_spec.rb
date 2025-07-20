require "rails_helper"

RSpec.describe Billing::Owner do
  subject(:billing) { Billing::Owner.new villa_owner, booking, booking.billings }

  let(:eps) { 1e-3 }

  shared_examples "only villa billing" do |values|
    its(:recipient) { is_expected.to eq villa_owner }
    its(:owner)     { is_expected.to eq villa_owner }

    its(:charges)           { is_expected.to be_empty }
    its(:accounting)        { is_expected.to be_within(eps).of values["accounting"] }
    its(:agency_fee)        { is_expected.to be_within(eps).of values["agency_fee"] }
    its(:agency_commission) { is_expected.to be_within(eps).of values["agency_commission"] }
    its(:payout)            { is_expected.to be_within(eps).of values["payout"] }
    its(:taxes)             { is_expected.to be_within(eps).of values["taxes"] }
    its(:id_string)         { is_expected.to eq "#{booking.number}-Owner-Villa-#{inquiry.currency}" }

    its(:villa_billing) { is_expected.not_to be_nil }
    its(:boat_billing)  { is_expected.to be_nil }

    context "with additional charges" do
      before do
        create :charge,
          villa_billing_id: inquiry.villa_billing_ids.first,
          value:            100,
          amount:           1
      end

      it { expect(billing.charges.map(&:sub_total).sum).to be_within(eps).of 100 }

      its(:charges) { is_expected.not_to be_empty }
      its(:payout)  { is_expected.to be_within(eps).of values["payout"] + 100 }
    end
  end

  shared_examples "boat and villa billing" do |values|
    let(:boat_owner) { villa_owner }

    its(:recipient)  { is_expected.to eq villa_owner }
    its(:owner)      { is_expected.to eq villa_owner }

    its(:charges)           { is_expected.to be_empty }
    its(:accounting)        { is_expected.to be_within(eps).of values["accounting"] }
    its(:agency_fee)        { is_expected.to be_within(eps).of values["agency_fee"] }
    its(:agency_commission) { is_expected.to be_within(eps).of values["agency_commission"] }
    its(:payout)            { is_expected.to be_within(eps).of values["payout"] }
    its(:taxes)             { is_expected.to be_within(eps).of values["taxes"] }
    its(:id_string)         { is_expected.to eq "#{booking.number}-Owner-Boat-Villa-#{inquiry.currency}" }

    its(:villa_billing) { is_expected.not_to be_nil }
    its(:boat_billing)  { is_expected.not_to be_nil }

    context "with additional charges" do
      before do
        create :charge,
          villa_billing_id: inquiry.villa_billing_ids.first,
          value:            100,
          amount:           1
        create :charge,
          villa_billing_id: nil,
          boat_billing_id:  inquiry.boat_billing_ids.first,
          value:            25,
          amount:           2
      end

      it { expect(billing.charges.map(&:sub_total).sum).to be_within(eps).of 150 }

      its(:charges) { is_expected.not_to be_empty }
      its(:payout)  { is_expected.to be_within(eps).of(values["payout"] + 150) }
    end
  end

  context "before 2019" do
    include_context "prepare billings"

    around do |ex|
      Timecop.travel Date.current.strftime("2016-%m-%d").to_date, &ex
    end

    it_behaves_like "only villa billing",
      "accounting"        => 1181.459,
      "agency_fee"        => -15,
      "agency_commission" => -201.801,
      "payout"            => 964.657,
      "taxes"             => 129.96

    it_behaves_like "boat and villa billing",
      "accounting"        => 1454.459,
      "agency_fee"        => -15,
      "agency_commission" => -228.099,
      "payout"            => 1211.359,
      "taxes"             => 146.34
  end

  context "after 2019" do
    include_context "prepare billings"

    around do |ex|
      Timecop.travel Date.current.strftime("2019-%m-%d").to_date, &ex
    end

    it_behaves_like "only villa billing",
      "accounting"        => 1176.161,
      "agency_fee"        => -15,
      "agency_commission" => -200.896,
      "payout"            => 960.264,
      "taxes"             => 135.258

    it_behaves_like "boat and villa billing",
      "accounting"        => 1447.879,
      "agency_fee"        => -15,
      "agency_commission" => -227.071,
      "payout"            => 1205.808,
      "taxes"             => 152.92
  end

  context "external booking" do
    include_context "prepare billings" do
      let(:external) { true }
      let(:currency) { Currency::USD }
    end

    around { |ex| Currency.with(currency, &ex) }

    it_behaves_like "only villa billing",
      "accounting"        => 1503.339,
      "agency_fee"        => -15,
      "agency_commission" => -257.550,
      "payout"            => 1230.789,
      "taxes"             => 172.884

    it_behaves_like "boat and villa billing",
      "accounting"        => 1865.780,
      "agency_fee"        => -15,
      "agency_commission" => -292.479,
      "payout"            => 1558.300,
      "taxes"             => 196.443
  end

  # Statement                gross       net
  # Rent boat             € 162,61  € 152,69
  # Boat instruction      € 150,00  € 140,85
  # Total taxable boat    € 312,61  € 293,53
  #  6.5% Sales tax                 €  19,08
  #
  # Accounting               gross       net
  # Total excluding taxes           € 293,53
  # Admin Commission               -€  30,54
  # Payout                € 282,07  € 262,99
  # Taxes total                     €  19,08
  describe "#payout_for_report" do
    include_context "prepare billings"

    context "boat_billing" do
      subject(:billing_owner) { Billing::Owner.new boat_billing.owner, boat_billing.booking, boat_billing }

      context "default" do
        let!(:boat_billing) { create :boat_billing }

        it "includes taxes (gross)" do
          expect(billing_owner.payout_for_report).to have_attributes value: be_within(0.01).of(282.07)
        end
      end

      context "owner net" do
        let!(:boat_billing) { create :boat_billing, :net_owner }

        it "does not include taxes (net)" do
          expect(billing_owner.payout_for_report).to have_attributes value: be_within(0.01).of(262.99)
        end
      end
    end
  end
end
