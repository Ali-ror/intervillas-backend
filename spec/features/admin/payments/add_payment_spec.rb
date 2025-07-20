require "rails_helper"

RSpec.feature "Zahlungen", :js do
  include_context "as_admin"

  shared_examples "add payment" do
    it "add payment" do
      visit "/admin/payments"
      find("tr", text: booking.number).first("td").click

      expect(page).to have_content "Neue Zahlung eintragen"
      within "tr", text: "Restzahlung" do
        click_on "übernehmen"
      end

      within ".form-group", text: "Datum" do
        date_range_picker.select_dates Date.current
      end
      click_on "Speichern"

      within "fieldset", text: "Zahlungseingänge bestätigen" do
        fill_in "Text", with: "hi"
        click_on "versenden"
      end

      expect(page).to have_flash "success", "Nachricht wird in Kürze versendet"
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq "#{booking.number}: Bestätigung Zahlungseingang - Intervilla"
      expect(mail.body.decoded).to include curr_values.lookup_value(
        "Mietkosten inkl. Kaution",
        format_options: { delimiter: "'", format: "%n" },
      ) # Vermutlich ein geschütztes Leerzeichen zwischen € und Zahl
      expect_occupancies_loaded
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR

    include_examples "add payment"
  end

  context "USD" do
    include_context "editable booking", Currency::USD

    include_examples "add payment"
  end
end
