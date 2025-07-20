require "rails_helper"

RSpec.describe Billing::Tenant do
  subject(:billing) { Billing::Tenant.new inquiry.customer, booking, booking.billings }

  let(:eps) { 1e-9 }

  include_examples "prepare billings"

  context "only villa billing" do
    its(:recipient) { is_expected.to eq(billing.customer).and eq(inquiry.customer) }

    describe "calculating deposits" do
      let(:villa_deposit) { billing.deposits[villa.display_name] }

      it { expect(billing.deposits).to be_a Hash }
      it { expect(billing.deposits.keys).to eq [villa.display_name] }

      it { expect(villa_deposit).to be_kind_of Billing::Position }
      it { expect(villa_deposit.subject).to be :deposit }
      it { expect(villa_deposit.context).to eq "villa" }
      it { expect(villa_deposit.gross).to be_within(eps).of(42.42) }
      it { expect(villa_deposit.taxes).to be_empty }
    end

    its(:total_deposit) { is_expected.to be_within(eps).of(42.42) }
    its(:charges)       { is_expected.to be_empty }
    its(:total_charges) { is_expected.to eq 0 }
    its(:total_energy)  { is_expected.to be_within(eps).of(149) }
    its(:total)         { is_expected.to be_within(eps).of(42.42 - 149) }

    its(:id_string)     { is_expected.to eq "IV-#{booking.id}-Tenant-EUR" }

    context "additional charges" do
      before do
        create :charge, villa_billing_id: inquiry.villa_billing_ids.first,
          value: 100, amount: 1
      end

      its(:total_charges) { is_expected.to be_within(eps).of(100) }
      its(:total)         { is_expected.to be_within(eps).of(42.42 - 249) }
    end
  end

  context "boat and villa billing" do
    let(:boat_owner) { villa_owner }

    its(:recipient) { is_expected.to eq(billing.customer).and eq(inquiry.customer) }

    describe "calculating deposits" do
      let(:villa_deposit) { billing.deposits[villa.display_name] }
      let(:boat_deposit)  { billing.deposits[boat.display_name] }

      it { expect(billing.deposits).to be_a Hash }
      it { expect(billing.deposits.keys).to eq [villa.display_name, boat.display_name] }

      it { expect(villa_deposit).to be_kind_of Billing::Position }
      it { expect(villa_deposit.subject).to be :deposit }
      it { expect(villa_deposit.context).to eq "villa" }
      it { expect(villa_deposit.gross).to be_within(eps).of(42.42) }
      it { expect(villa_deposit.taxes).to be_empty }

      it { expect(boat_deposit).to be_kind_of Billing::Position }
      it { expect(boat_deposit.subject).to be :deposit }
      it { expect(boat_deposit.context).to eq "boat" }
      it { expect(boat_deposit.gross).to be_within(eps).of(900) }
      it { expect(boat_deposit.taxes).to be_empty }
    end

    its(:total_deposit) { is_expected.to be_within(eps).of(942.42) }
    its(:charges)       { is_expected.to be_empty }
    its(:total_charges) { is_expected.to eq 0 }
    its(:total_energy)  { is_expected.to be_within(eps).of(149) }
    its(:total)         { is_expected.to be_within(eps).of(942.42 - 149) }

    its(:id_string)     { is_expected.to eq "IV-#{booking.id}-Tenant-EUR" }

    context "additional charges" do
      before do
        create :charge, villa_billing_id: inquiry.villa_billing_ids.first,
          value: 100, amount: 1
        create :charge, villa_billing_id: nil, boat_billing_id: inquiry.boat_billing_ids.first,
          value: 25, amount: 2
      end

      its(:total_charges) { is_expected.to be_within(eps).of(150) }
      its(:total)         { is_expected.to be_within(eps).of(942.42 - (149 + 150)) }

      context "handling fee" do
        before do
          create :clearing_item, inquiry: booking.inquiry, category: "handling", price: 42.01
        end

        its(:total_charges) { is_expected.to be_within(eps).of(150) }
        its(:total)         { is_expected.to be_within(eps).of(942.42 - (149 + 150)) }
      end
    end
  end
end
