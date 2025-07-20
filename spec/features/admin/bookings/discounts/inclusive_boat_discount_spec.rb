require "rails_helper"

RSpec.feature "Rabatte", :js do
  include_context "as_admin"

  shared_examples "mit Inklusiv-Boot Rabatt hinzufügen" do
    scenario "mit Inklusiv-Boot Rabatt hinzufügen" do
      visit edit_admin_booking_path(booking)
      expect(page).to have_no_content "Bitte warten"
      expect_price_row_value_lookup("7 Nächte Grundpreis")
      expect_price_row_value_lookup("Mietkosten", :with_mandatory_boat)

      add_discount("Haus", 100)

      expect_price_row_value_lookup("Mietkosten", :with_mandatory_boat_discounted)
      click_on "Speichern"
      expect_saved
      expect_price_row_value_lookup("Mietkosten", :with_mandatory_boat_discounted)
      create_billing
      # Mietpreis auf der Abrechnung um 60 geringer
      expect_billing_row(*curr_values.lookup("Rent house", :with_mandatory_boat_discounted))
      # Bootpreis auf der Abrechnung um 40 geringer
      expect_billing_row(*curr_values.lookup("Rent boat", :with_mandatory_boat_discounted))
    end
  end

  context "EUR" do
    include_context "editable booking with boat", Currency::EUR, state: :inclusive

    include_examples "mit Inklusiv-Boot Rabatt hinzufügen"
  end

  context "USD" do
    include_context "editable booking with boat", Currency::USD, state: :inclusive

    include_examples "mit Inklusiv-Boot Rabatt hinzufügen"
  end
end
