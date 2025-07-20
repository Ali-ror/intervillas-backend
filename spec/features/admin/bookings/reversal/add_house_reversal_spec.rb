require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "Haus Stornogebühren hinzufügen" do
    scenario "Haus Stornogebühren hinzufügen" do
      visit edit_admin_booking_path(booking)
      expect(page).not_to have_content "Bitte warten"
      expect_price_row_value_lookup("7 Nächte Grundpreis")
      expect_price_row_value_lookup("Mietkosten", :with_boat)

      add_reversal("Haus", 50, note: "Stornonotiz")

      expect_price_row_value_lookup("Mietkosten", :with_boat_reversal)
      click_on "Speichern"
      expect_saved
      expect_price_row_value_lookup("Mietkosten", :with_boat_reversal)
      create_billing
      # Mietpreis auf der Abrechnung um 50 höher
      expect_billing_row(*curr_values.lookup("Rent house", :with_boat_reversal,
        format_options: OdsTestValues::SWISS_DELIMITER))
    end
  end

  context "EUR" do
    include_context "editable booking with boat", Currency::EUR

    include_examples "Haus Stornogebühren hinzufügen"
  end

  context "USD" do
    include_context "editable booking with boat", Currency::USD

    include_examples "Haus Stornogebühren hinzufügen"
  end
end
