require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "Anzahl der Reisenden ändern" do
    feature "Anzahl der Reisenden ändern" do
      scenario do
        visit edit_admin_booking_path(booking)

        click_on "Buchungsdaten"
        expect(page).not_to have_content "Bitte warten"
        adult_price = find("tr", text: "2 Erwachsene").find("td.text-right:last-child").text

        within "fieldset", text: "Reisende" do
          [
            "Erwachsene",
            "Kinder bis 6 J.",
            "Kinder bis 12 J.",
          ].each do |price_category|
            2.times do
              click_on "Reisenden hinzufügen"
              within find_all("tbody tr").last do
                select price_category, from: "Preiskategorie"
                find("[placeholder='Nachname']").fill_in with: "Reisender"
                fill_in "Vorname", with: "Namenloser"
              end
            end
          end
        end

        new_adult_price = find("tr", text: "4 Erwachsene").find("td.text-right:last-child").text
        expect(new_adult_price).not_to eq adult_price

        within_price_table do
          expect_price_row_value_lookup("7 Nächte 4 Erwachsene", :priced_as_2)
          # normal_price
          within_price_row "4 Erwachsene" do
            click_on "Normalpreis vorhanden"
            click_on "Normalpreis von #{curr_values.single_rate(occupancy: 4, format_options: OdsTestValues::ONLY_DIGIT)}"
          end
          expect_price_row_value_lookup("7 Nächte 4 Erwachsene")
        end

        click_on "Speichern"
        expect_saved
        expect(page).not_to have_content "Bitte warten"

        within_price_table do
          expect_price_row_value_lookup("7 Nächte 4 Erwachsene")
          expect_price_row_value_lookup("7 Nächte 2 Kinder bis 6 J.")
          expect_price_row_value_lookup("7 Nächte 2 Kinder bis 12 J.")
          expect_price_row_value_lookup("Mietpreis", :travelers_count_spec)
          expect_price_row_value_lookup("Mietkosten", :travelers_count_spec)
          expect_price_row_value_lookup("Mietkosten inkl. Kaution", :travelers_count_spec)
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")
        end
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, legacy_prices: true

    include_examples "Anzahl der Reisenden ändern"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, legacy_prices: true

    include_examples "Anzahl der Reisenden ändern"
  end
end
