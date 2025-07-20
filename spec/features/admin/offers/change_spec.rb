require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "ändern" do
    feature "ändern", :vcr do
      let!(:inquiry) { create_villa_inquiry(start_date: Date.current + 2.days, end_date: Date.current + 10.days, currency: curr).inquiry }

      scenario do
        visit admin_inquiries_path

        within "tr", text: inquiry.number do
          click_on "bearbeiten"
        end

        expect_price_row_field("Grundpreis", with: curr_values.lookup_category(:base_rate, format: false))
        expect_price_row_value_lookup("8 Nächte Grundpreis")

        fill_in_clearing_item "Grundpreis", with: 198
        expect_price_row_value_lookup("8 Nächte Grundpreis", :change_spec)

        click_on "Speichern"

        expect_saved
        expect_price_row_field "Grundpreis", with: 198

        within_price_table do
          expect_price_row_value_lookup("8 Nächte Grundpreis", :change_spec)
          expect_price_row_value_lookup("Mietpreis", :change_spec)
          expect_price_row_value_lookup("Mietkosten", :change_spec)
          expect_price_row_value_lookup("Mietkosten inkl. Kaution", :change_spec)
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")
        end

        click_on "Angebotsmail senden"
        expect(page).to have_no_content "Hole Belegungsdaten"
        expect_occupancies_loaded
      end
    end
  end

  context "EUR" do
    include_context "offers", Currency::EUR

    include_examples "ändern"
  end

  context "USD" do
    include_context "offers", Currency::USD

    include_examples "ändern"
  end
end
