require "rails_helper"
require "billing"

RSpec.describe Billing do
  subject { Billing.new booking }

  include_examples "prepare billings"

  context "for a booking without boat" do
    its(:id) { is_expected.to eq booking.id } # sanity check
    its(:tenant_billing) { is_expected.to be_kind_of Billing::Tenant }

    it "has one owner billing" do
      ob = subject.owner_billings
      expect(ob.size).to be 1
      expect(ob[0]).to be_kind_of Billing::Owner
    end
  end

  context "for a booking with boat and villa" do
    let(:boat_owner) { villa_owner }

    it "has one owner billing" do
      ob = subject.owner_billings
      expect(ob.size).to be 1
      expect(ob[0]).to be_kind_of Billing::Owner
    end

    context "when owners are different" do
      let(:boat_owner)  { create :contact }

      it "has two owner billing" do
        ob = subject.owner_billings
        expect(ob.size).to be 2
        expect(ob.map(&:owner)).to include(boat_owner, villa_owner)
      end
    end
  end
end
