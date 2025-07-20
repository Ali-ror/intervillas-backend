require "rails_helper"

RSpec.feature "new booking with weekly prices", :js, vcr: { cassette_name: "admin_villa/geocode" } do
  include_context "as_admin"

  shared_examples "weekly prices" do
    let!(:villa) { create :villa, :with_descriptions, :bookable, :with_weekly_prices }
    let(:villa_inquiry_params) { attributes_for :villa_inquiry, adults: 3, children_under_12: 1 }

    it "creates booking" do
      inquiry = create_booking_request(villa_inquiry_params) {
        within_price_table do
          click_on "Details anzeigen"
          expect(page).to have_no_content "Boot"
          expect(page).to have_no_content "weitere Person(en)"
          expect(page).to have_no_content "Kinder bis 12"
        end

        expect_price_breakdown_lookup("Grundpreis", "14 Nächte 2 Erwachsene")
        expect_price_breakdown_lookup("Endreinigung")
      }
      create_customer(newsletter: true)
      expect(page).to have_content I18n.t("bookings.create.vielen_dank")

      inquiry.reload
      expect(inquiry.customer.newsletter).to be true
      expect(inquiry.customer.phone).not_to be_blank
      confirm_booking_request(inquiry, customer_params: customer_params)
      expect(inquiry.currency).to eq curr

      # Preise in Emails sollen auch in der gebuchten Währung sein
      expect(open_email(customer_params[:email])).to have_content Currency.symbol(curr)

      ci = inquiry.clearing_items
      expect(ci.where("category like 'base_rate%'")).not_to be_exist
      expect(ci.where("category like 'children_under_12%'")).not_to be_exist
      expect(ci.where(category: "weekly_rate")).to be_exist
    end
  end

  context "in EUR" do
    include_context "prepare new booking", Currency::EUR
    include_examples "weekly prices"
  end

  context "in USD" do
    include_context "prepare new booking", Currency::USD
    include_examples "weekly prices"
  end
end
