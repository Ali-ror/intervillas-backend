require "rails_helper"

RSpec.feature "Rabatte", :js do
  include_context "as_admin"

  shared_examples "Repeater Rabatt hinzufügen" do
    # Wird beim Eigentümer abgezogen, aber nicht von der Kommission/Tax
    scenario "Repeater Rabatt hinzufügen" do
      visit edit_admin_booking_path(booking)
      expect(page).not_to have_content "Bitte warten"
      expect_price_row_value_lookup("7 Nächte Grundpreis")
      expect_price_row_value_lookup("Mietkosten", :with_boat)

      add_discount("Repeater", 50)

      expect_price_row_value_lookup("Mietkosten", :with_boat_discounted)
      click_on "Speichern"
      expect_saved
      expect_price_row_value_lookup("Mietkosten", :with_boat_discounted)
      create_billing

      expect_billing_row(*curr_values.lookup("Rent house",
        format_options: OdsTestValues::SWISS_DELIMITER))
      expect_billing_row(*curr_values.lookup("Repeater Discount",
        format_options: OdsTestValues::RAILS_CURRENCY_FORMAT))

      # 50 € weniger payout
      expect_billing_row(*curr_values.lookup("Payout", :intervillas_discount,
        format_options: OdsTestValues::SWISS_DELIMITER))
    end
  end

  context "EUR" do
    include_context "editable booking with boat", Currency::EUR

    include_examples "Repeater Rabatt hinzufügen"
  end

  context "USD" do
    include_context "editable booking with boat", Currency::USD

    include_examples "Repeater Rabatt hinzufügen"
  end
end
