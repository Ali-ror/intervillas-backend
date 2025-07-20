require "rails_helper"

RSpec.describe Search do
  shared_examples "a successful search" do
    # search for customer last_name
    it "gets Inquiry of Customer" do
      expect(results).to include booking.inquiry
    end

    it "does not get Inquiry of another Customer" do
      expect(results).not_to include other_booking.inquiry
    end
  end

  describe ".customer(user, query:, villa_id: nil, boat_id: nil, **)" do
    let(:customer) { booking.customer }
    let!(:other_booking) { create_full_booking }

    context "as admin" do
      # liefert alle Anfragen
      subject(:results) { Search.customer(admin, query: customer.last_name) }

      let(:booking) { create_full_booking }
      let(:admin) { create(:user, :with_password, :with_second_factor, admin: true) }

      it_behaves_like "a successful search"
    end

    context "as Owner" do
      # liefert nur Anfragen, die ein Objekt von diesem Eigentümer
      # betreffen
      subject(:results) { Search.customer(owner_user, query: customer.last_name) }

      let(:booking) { create_full_booking with_owner: true }
      let(:owner) { booking.villa.owner }
      let(:owner_user) { create :user, contacts: [owner] }

      it_behaves_like "a successful search"
    end

    context "as Manager" do
      # liefert nur Anfragen, die ein von dieser Hausverwaltung
      # betreutes Objekt betreffen
      subject(:results) { Search.customer(manager_user, query: customer.last_name) }

      let(:booking) { create_full_booking with_manager: true }
      let(:manager) { booking.villa.manager }
      let(:manager_user) { create :user, contacts: [manager] }

      it_behaves_like "a successful search"
    end
  end
end
