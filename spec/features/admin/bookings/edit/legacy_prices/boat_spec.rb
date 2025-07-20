require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "Boot hinzubuchen" do
    describe "Boot hinzubuchen" do
      let(:villa)      { booking.villa }
      let(:boat)       { villa.optional_boats.first }
      let(:other_boat) { villa.optional_boats.last }

      before do
        create_boat_for_villa(villa)

        boat_inq = create :boat_inquiry,
          boat:       create_boat_for_villa(villa),
          inquiry:    create(:inquiry),
          start_date: villa_inquiry.end_date - 4.days,
          end_date:   villa_inquiry.end_date - 1.day

        create(:booking, inquiry: boat_inq.inquiry, state: "booked")
      end

      scenario do
        visit edit_admin_booking_path(booking)

        within_price_table do
          expect_price_row_value_lookup("7 Nächte 2 Erwachsene")
          expect_price_row_value_lookup("Mietpreis")
          expect_price_row_value_lookup("Mietkosten")
          expect_price_row_value_lookup("Mietkosten inkl. Kaution")
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")
        end

        click_on "Boot hinzufügen"
        expect(page).to have_no_content "Hole Belegungsdaten"
        ui_select boat.admin_display_name, from: "Boot"

        expect(page).to have_no_selector ".admin-boat-selector .form-group.disabled"
        within "form .form-group", text: "Boot" do
          date_range_picker.select_dates \
            villa_inquiry.start_date + 1.day,
            villa_inquiry.end_date - 3.days
        end

        # check if changing boat also checks against DRP's availability list
        # and displays an appropriate hint
        hint = "Das Boot ist in dem gewählten Zeitraum nicht verfügbar"
        ui_select other_boat.admin_display_name, from: "Boot"
        expect(page).to have_content hint
        ui_select boat.admin_display_name, from: "Boot"
        expect(page).to have_no_content hint

        within_price_table do
          expect_price_row_field("4 Tage 1 Boot", with: curr_values.lookup_category(:boat_daily, format: false))
        end

        fill_in_clearing_item "Boot-Anlieferung", with: 300
        fill_in_clearing_item "Boot-Kaution", with: 400
        fill_in_clearing_item "4 Tage 1 Boot", with: 200
        new_boat_price = find("tr", text: "4 Tage 1 Boot").find("td.text-right:last-child").text
        expect(new_boat_price).to eq "800,00 " + Currency.symbol(curr)

        execute_script "window.scrollTo(0,0)"
        click_on "Speichern"

        expect_saved

        within "form .form-group", text: "Boot" do
          date_range_picker.within_wrapper do
            s = villa_inquiry.start_date + 1.day
            e = villa_inquiry.end_date - 3.days

            expect(page).to display_date_range_picker_dates(s, e)
          end
        end

        within_price_table do
          expect_price_row_value_lookup("7 Nächte 2 Erwachsene")
          expect_price_row_value_lookup("4 Tage 1 Boot", :custom_boat_price)
          expect_price_row_value_lookup("Mietpreis", :custom_boat_price)
          expect_price_row_value_lookup("Mietkosten", :custom_boat_price)
          expect_price_row_value_lookup("Mietkosten inkl. Kaution", :custom_boat_price)
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")
        end
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, legacy_prices: true

    include_examples "Boot hinzubuchen"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, legacy_prices: true

    include_examples "Boot hinzubuchen"
  end
end
