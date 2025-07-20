require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "Bearbeitungsgebühr hinzufügen" do
    scenario "Bearbeitungsgebühr hinzufügen" do
      visit edit_admin_booking_path(booking)
      expect(page).not_to have_content "Bitte warten"
      expect_price_row_value_lookup("Mietkosten")

      click_on "Posten hinzufügen"
      click_on "Pet-Fee"
      within "tr", text: "Pet-Fee" do
        click_on "löschen" # "oops, verklickt"
      end

      click_on "Posten hinzufügen"
      click_on "Bearbeitungsgebühr"
      fill_in_clearing_item "Bearbeitungsgebühr", with: 50, note: "Gebühr für Umbuchung"
      expect_price_row_value_lookup("Mietkosten", :with_handling)

      click_on "Speichern"
      expect_saved
      expect_price_row_value_lookup("Mietkosten", :with_handling)

      expect(booking.reload.clearing_items).not_to include have_attributes(category: "pet_fee")
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR

    include_examples "Bearbeitungsgebühr hinzufügen"
  end

  context "USD" do
    include_context "editable booking", Currency::USD

    include_examples "Bearbeitungsgebühr hinzufügen"
  end
end
