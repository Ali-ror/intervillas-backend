require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  def expect_correct_pricetable
    within_price_table do
      expect_price_row_value_lookup("7 Nächte Grundpreis", :alternative_villa)
      expect_price_row_value_lookup("Mietpreis", :alternative_villa)
      expect_price_row_value_lookup("Mietkosten", :alternative_villa)
      expect_price_row_value_lookup("Mietkosten inkl. Kaution", :alternative_villa)
      expect_price_row_field_lookup("Endreinigung")
      expect_price_row_field_lookup("Haus-Kaution")
    end
  end

  shared_examples "Villa ändern" do
    feature "Villa ändern" do
      let!(:other_villa) { create :villa, :with_owner, :bookable, created_at: 1.month.ago }

      before do
        other_villa.villa_price.update base_rate: (53.53 * 2)
      end

      scenario do
        visit edit_admin_booking_path(booking)

        expect(page).to have_ui_select "Villa", selected: villa_inquiry.villa.name

        sleep 1 # dieses sleep ist wichtig
        ui_select other_villa.name, from: "Villa"
        expect(page).to have_no_content "Termine werden geladen"
        expect(page).to have_no_content "Preisberechnung nicht möglich"

        within_price_table do
          expect_price_row_value_lookup("7 Nächte Grundpreis")
          # normal_price
          within_price_row "Grundpreis" do
            click_on "Normalpreis vorhanden"
            click_on "Normalpreis von #{curr_values.lookup_category(:alternative_villa_base, format_options: OdsTestValues::ONLY_DIGIT)}"
          end
        end

        expect_correct_pricetable

        check "Villa oder Buchungszeitraum haben sich geändert. Alle Aufschläge/Rabatte wurden kontrolliert."

        click_on "Speichern"

        expect_saved
        expect(page).to have_ui_select "Villa", selected: other_villa.name
        expect(page).to have_no_content "Bitte warten"

        expect_correct_pricetable
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR

    include_examples "Villa ändern"
  end

  context "USD" do
    include_context "editable booking", Currency::USD

    include_examples "Villa ändern"
  end
end
