require "rails_helper"

RSpec.feature "Hochsaison", :js do
  include_context "as_admin"

  shared_examples "Hochsaison hinzufügen" do
    context "Hochsaison hinzufügen" do
      delegate :start_date, :end_date, to: :villa_inquiry

      scenario "aktualisiert Preistabelle" do
        visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

        expect_price_row_value_lookup("14 Nächte Grundpreis")
        expect_price_row_value_lookup("Mietpreis", "14_nights")
        expect_price_row_value_lookup("Mietkosten", "14_nights")
        expect_price_row_value_lookup("Mietkosten inkl. Kaution", "14_nights")

        within ".sidebar-right .details-villa" do
          click_on "Hochsaison: Aufschlag hinzufügen"
        end

        within ".edit-discount-modal" do
          date_range_picker.select_dates start_date, end_date
          fill_in "Aufschlag", with: 20
          click_on "Speichern"
        end

        expect_price_row_value_lookup("14 Nächte Grundpreis")
        expect_price_row_value_lookup("14 Nächte + Hochsaison")
        expect_price_row_value_lookup("Mietpreis", :high_season)
        expect_price_row_value_lookup("Mietkosten", :high_season)
        expect_price_row_value_lookup("Mietkosten inkl. Kaution", :high_season)
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, nights: 14

    include_examples "Hochsaison hinzufügen"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, nights: 14

    include_examples "Hochsaison hinzufügen"
  end
end
