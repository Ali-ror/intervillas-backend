require "rails_helper"

RSpec.feature "Rabatte", :js do
  include_context "as_admin"

  shared_examples "Haus Rabatt hinzufügen" do
    scenario "Haus Rabatt hinzufügen" do
      visit edit_admin_booking_path(booking)
      expect(page).to have_no_content "Bitte warten"
      expect_price_row_value_lookup("7 Nächte Grundpreis")
      expect_price_row_value_lookup("Mietkosten", :with_boat)

      add_discount("Haus", 50)

      expect_price_row_value_lookup("Mietkosten", :with_boat_discounted)
      click_on "Speichern"
      expect_saved
      expect_price_row_value_lookup("Mietkosten", :with_boat_discounted)
      create_billing
      # Mietpreis auf der Abrechnung um 50 geringer
      expect_billing_row(*curr_values.lookup("Rent house", :with_boat_discounted,
        format_options: OdsTestValues::SWISS_DELIMITER))
    end
  end

  context "EUR" do
    include_context "editable booking with boat", Currency::EUR

    include_examples "Haus Rabatt hinzufügen"
  end

  context "USD" do
    include_context "editable booking with boat", Currency::USD

    include_examples "Haus Rabatt hinzufügen"
  end
end
