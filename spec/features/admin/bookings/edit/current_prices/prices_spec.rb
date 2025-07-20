require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "Preise ändern" do
    feature "Preise ändern" do
      let(:inquiry) { booking.inquiry }

      scenario do
        visit edit_admin_booking_path(booking)

        within_price_table do
          expect_price_row_value_lookup("7 Nächte Grundpreis")
          expect_price_row_value_lookup("Mietpreis")
          expect_price_row_value_lookup("Mietkosten")
          expect_price_row_value_lookup("Mietkosten inkl. Kaution")
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")

          expect(page).to have_no_content "Bearbeitungsgebühr"
        end

        click_on "Posten hinzufügen"
        click_on "Bearbeitungsgebühr"

        fill_in_clearing_item "Bearbeitungsgebühr", with: 50, note: "Deppen-Aufschlag"
        fill_in_clearing_item "Grundpreis", with: 198

        new_adult_price = find("#price_table tr", text: "Grundpreis").find("td.text-right:last-child").text
        expect(new_adult_price).to eq curr_values.lookup("7 Nächte Grundpreis", :custom_prices)[1]

        click_on "Speichern"

        expect_saved

        within_price_table do
          expect_price_row_field "Grundpreis", with: 198
          expect_price_row_field "Bearbeitungsgebühr", with: 50
        end

        within_price_table do
          expect_price_row_value_lookup("7 Nächte Grundpreis", :custom_prices)
          expect_price_row_value_lookup("Mietpreis", :custom_prices)
          expect_price_row_value_lookup("Mietkosten", :custom_prices)
          expect_price_row_value_lookup("Mietkosten inkl. Kaution", :custom_prices)
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")
          expect_price_row_field_lookup("Bearbeitungsgebühr")
        end
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR

    include_examples "Preise ändern"
  end

  context "USD" do
    include_context "editable booking", Currency::USD

    include_examples "Preise ändern"
  end
end
