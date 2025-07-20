require "rails_helper"

RSpec.feature "new booking with mandatory boat", :js, vcr: { cassette_name: "admin_villa/geocode" } do
  include_context "as_admin"

  shared_examples "with mandatory boat" do
    let!(:villa) { create :villa, :with_mandatory_boat, :with_descriptions, :bookable, :with_owner }

    before do
      Boat.last.update! owner: create(:contact)
    end

    it "creates booking" do
      inquiry = create_booking_request(villa_inquiry_params) {
        within_price_table { click_on "Details anzeigen" }
        expect_price_row_value_lookup("Boot-Anlieferung")
      }

      create_customer
      inquiry.reload
      expect(inquiry.customer.newsletter).to be false
      expect(inquiry.boat_inquiry).to be_present
      expect(page).to have_content I18n.t("bookings.create.vielen_dank")
      confirm_booking_request(inquiry, customer_params: customer_params)
      click_on "zur Buchungsbestätigung"

      expect(open_email(villa.owner.emails.first)).to be_present
      expect(open_email(villa.inclusive_boat.owner.emails.first)).not_to be_present
    end
  end

  context "in EUR" do
    include_context "prepare new booking", Currency::EUR
    include_examples "with mandatory boat"
  end

  context "in USD" do
    include_context "prepare new booking", Currency::USD
    include_examples "with mandatory boat"
  end
end
