require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "Boot ändern" do
    scenario "Boot ändern" do
      visit edit_admin_booking_path(booking)

      expect(page).not_to have_content "Bitte warten"
      within("form .form-group", text: "Boot") do
        date_range_picker.within_wrapper do
          s = boat_inquiry.start_date
          e = boat_inquiry.end_date

          expect(page).to display_date_range_picker_dates(s, e)
        end
      end

      new_end_date = boat_inquiry.end_date - 2.days
      boat_price   = find("tr", text: "6 Tage 1 Boot").find("td.text-right:last-child").text

      within("form .form-group", text: "Boot") do
        date_range_picker.select_dates(boat_inquiry.start_date, new_end_date)
      end

      within "tr", text: "4 Tage 1 Boot" do
        find("input").fill_in with: 200
        new_boat_price = find("td.text-right:last-child").text
        expect(new_boat_price).not_to eq boat_price
        expect(new_boat_price).to eq curr_values.lookup("4 Tage 1 Boot", :custom_boat_price)[1]
      end

      fill_in_clearing_item "Boot-Anlieferung", with: ""
      fill_in_clearing_item "Boot-Kaution", with: 400

      click_on "Speichern"

      expect_saved

      within("form .form-group", text: "Boot") do
        date_range_picker.within_wrapper do
          expect(page).to display_date_range_picker_dates boat_inquiry.start_date, new_end_date
        end
      end

      within_price_table do
        expect_price_row_value_lookup("7 Nächte Grundpreis")
        expect_price_row_value_lookup("4 Tage 1 Boot", :custom_boat_price)
        expect_price_row_value_lookup("Mietpreis", :custom_boat_price)
        expect_price_row_value_lookup("Mietkosten", :changed_boat)
        expect_price_row_value_lookup("Mietkosten inkl. Kaution", :changed_boat)
        expect_price_row_field_lookup("Endreinigung")
        expect_price_row_field_lookup("Haus-Kaution")
        expect_price_row_field_lookup("Boot-Kaution", :custom_boat_price)

        within_price_row "Boot-Kaution" do
          expect(page).to have_button "Normalpreis vorhanden"
        end
      end
    end
  end

  context "EUR" do
    include_context "editable booking with boat", Currency::EUR

    include_examples "Boot ändern"
  end

  context "USD" do
    include_context "editable booking with boat", Currency::USD

    include_examples "Boot ändern"
  end
end
