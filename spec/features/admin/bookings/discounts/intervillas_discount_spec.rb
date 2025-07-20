require "rails_helper"

RSpec.feature "Rabatte", :js do
  include_context "as_admin"
  # Wird nicht beim Eigentümer abgezogen siehe intervillas/support#236
  shared_examples "Intervilla Rabatt hinzufügen" do
    scenario "Intervilla Rabatt hinzufügen" do
      visit edit_admin_booking_path(booking)
      expect(page).to have_no_content "Bitte warten"
      expect_price_row_value_lookup("7 Nächte Grundpreis")
      expect_price_row_value_lookup("Mietkosten", :with_boat)

      add_discount("Intervilla", 50)

      expect_price_row_value_lookup("Mietkosten", :with_boat_discounted)
      click_on "Speichern"
      expect_saved
      expect_price_row_value_lookup("Mietkosten", :with_boat_discounted)
      create_billing
      # Mietpreis auf der Abrechnung *nicht* um 50 geringer
      expect_billing_row(*curr_values.lookup("Rent house",
        format_options: OdsTestValues::SWISS_DELIMITER))
    end
  end

  context "EUR" do
    include_context "editable booking with boat", Currency::EUR

    include_examples "Intervilla Rabatt hinzufügen"
  end

  context "USD" do
    include_context "editable booking with boat", Currency::USD

    include_examples "Intervilla Rabatt hinzufügen"
  end
end
