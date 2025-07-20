require "rails_helper"

RSpec.feature "new booking dicarding optional boat", :js, vcr: { cassette_name: "admin_villa/geocode" } do
  include_context "as_admin"

  shared_examples "with optional boat not selected" do
    let!(:villa) { create :villa, :with_optional_boat, :with_descriptions, :bookable }

    it "creates booking" do
      inquiry = create_booking_request(villa_inquiry_params) {
        within_price_table { click_on "Details anzeigen" }
        expect_price_breakdown_lookup("Grundpreis für 2 Pers.", "14 Nächte Grundpreis")
      }
      click_on "Weiter ohne Boot"
      create_customer
      expect(page).to have_content I18n.t("bookings.create.vielen_dank")

      inquiry.reload
      confirm_booking_request(inquiry, customer_params: customer_params)
      inquiry.reload
      expect(inquiry.boat_inquiry).not_to be_present
    end
  end

  context "in EUR" do
    include_context "prepare new booking", Currency::EUR
    include_examples "with optional boat not selected"
  end

  context "in USD" do
    include_context "prepare new booking", Currency::USD
    include_examples "with optional boat not selected"
  end
end
