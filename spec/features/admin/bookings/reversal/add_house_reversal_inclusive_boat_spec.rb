require "rails_helper"

RSpec.feature "Stornogebühren hinzufügen", :js do
  include_context "as_admin"

  shared_examples "Stornogebühren hinzufügen" do
    scenario "Stornogebühren hinzufügen" do
      visit edit_admin_booking_path(booking)
      expect(page).not_to have_content "Bitte warten"
      expect_price_row_value_lookup("7 Nächte Grundpreis")
      expect_price_row_value_lookup("Mietkosten", :with_mandatory_boat)

      add_reversal("Haus", 100, note: "Stornonotiz")

      expect_price_row_value_lookup("Mietkosten", :boat_inclusive_reversal)
      click_on "Speichern"
      expect_saved
      expect_price_row_value_lookup("Mietkosten", :boat_inclusive_reversal)
      create_billing
      # Mietpreis auf der Abrechnung um 100 höher
      expect_billing_row(*curr_values.lookup("Rent house", :boat_inclusive_reversal))
      expect_billing_row(*curr_values.lookup("Rent boat", :boat_inclusive_reversal))
    end
  end

  context "EUR" do
    include_context "editable booking with boat", Currency::EUR, state: :inclusive

    include_examples "Stornogebühren hinzufügen"
  end

  context "USD" do
    include_context "editable booking with boat", Currency::USD, state: :inclusive

    include_examples "Stornogebühren hinzufügen"
  end
end
