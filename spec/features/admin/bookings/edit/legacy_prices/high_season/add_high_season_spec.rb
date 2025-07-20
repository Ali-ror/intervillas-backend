require "rails_helper"

RSpec.feature "Hochsaison", :js do
  include_context "as_admin"

  shared_examples "Hochsaison hinzufügen" do
    context "Hochsaison hinzufügen" do
      scenario "aktualisiert Preistabelle" do
        visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

        within_price_table do
          expect_price_row_value_lookup("14 Nächte 2 Erwachsene")
          expect_price_row_value_lookup("Mietpreis", "14_nights")
          expect_price_row_value_lookup("Mietkosten", "14_nights")
          expect_price_row_value_lookup("Mietkosten inkl. Kaution", "14_nights")
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")
        end

        within ".sidebar-right .details-villa" do
          click_on "Hochsaison: Aufschlag hinzufügen"
        end

        within ".edit-discount-modal" do
          date_range_picker.select_dates villa_inquiry.start_date, villa_inquiry.end_date
          fill_in "Aufschlag", with: 20
          click_on "Speichern"
        end

        within_price_table do
          expect_price_row_value_lookup("14 Nächte 2 Erwachsene")
          expect_price_row_value_lookup("14 Nächte 2 + Hochsaison")
          expect_price_row_value_lookup("Mietpreis", :high_season)
          expect_price_row_value_lookup("Mietkosten", :high_season)
          expect_price_row_value_lookup("Mietkosten inkl. Kaution", :high_season)
          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Haus-Kaution")
        end
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, legacy_prices: true, nights: 14

    include_examples "Hochsaison hinzufügen"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, legacy_prices: true, nights: 14

    include_examples "Hochsaison hinzufügen"
  end
end
