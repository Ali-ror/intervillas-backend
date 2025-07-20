require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js, vcr: { cassette_name: "villa/geocode" } do
  include_context "as_admin"

  # TODO: test how this behaves when changing Villa#minimum_people, i.e.
  #       `before { booking.villa_inquiry.villa.update minimum_people: 10 }`
  shared_examples "Anzahl der Reisenden ändern" do
    it "ändert Anzahl der Reisenden" do
      visit edit_admin_booking_path(booking)

      click_on "Buchungsdaten"
      expect(page).not_to have_content "Bitte warten"

      expect_price_row_value_lookup("7 Nächte Grundpreis")
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

      within_price_table do
        expect_price_row_value_lookup("7 Nächte Grundpreis")
        expect_price_row_value_lookup("7 Nächte 2 weitere Person(en)")
      end

      click_on "Speichern"
      expect_saved
      expect(page).not_to have_content "Bitte warten"

      within_price_table do
        expect_price_row_value_lookup("7 Nächte Grundpreis")
        expect_price_row_value_lookup("7 Nächte 2 weitere Person(en)")
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

  context "EUR" do
    include_context "editable booking", Currency::EUR

    it_behaves_like "Anzahl der Reisenden ändern"
  end

  context "USD" do
    include_context "editable booking", Currency::USD

    it_behaves_like "Anzahl der Reisenden ändern"
  end
end
