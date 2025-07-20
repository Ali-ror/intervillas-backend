require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "Zeiten ändern" do
    feature "Zeiten ändern" do
      around do |ex|
        raise_server_errors          = Capybara.raise_server_errors
        Capybara.raise_server_errors = false
        ex.call
      ensure
        Capybara.raise_server_errors = raise_server_errors
      end

      scenario do
        visit edit_admin_booking_path(booking)

        click_on "Buchungsdaten"
        within "fieldset", text: "Reisende" do
          expect(page).to have_content villa_inquiry.start_date.strftime("%d.%m.%Y")
        end

        new_start_date = villa_inquiry.start_date - 2.days
        new_end_date   = villa_inquiry.end_date + 2.days

        within "fieldset", text: "Reisende" do
          all("tbody tr td:nth-child(5)").each do |td|
            within td do
              date_range_picker.select_dates new_start_date, new_end_date
            end
          end
        end

        within_price_table do
          expect_price_row_value_lookup("11 Nächte Grundpreis")
        end

        check "Villa oder Buchungszeitraum haben sich geändert. Alle Aufschläge/Rabatte wurden kontrolliert."

        click_on "Speichern"
        expect_saved

        within "fieldset", text: "Reisende" do
          expect(page).to have_content new_start_date.strftime("%d.%m.%Y")
          expect(page).to have_content new_end_date.strftime("%d.%m.%Y")
        end

        within_price_table do
          expect_price_row_value_lookup("11 Nächte Grundpreis")
        end
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR

    include_examples "Zeiten ändern"
  end

  context "USD" do
    include_context "editable booking", Currency::USD

    include_examples "Zeiten ändern"
  end
end
