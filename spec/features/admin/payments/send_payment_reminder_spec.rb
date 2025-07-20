require "rails_helper"

RSpec.feature "Zahlungen", :js do
  include_context "as_admin"

  shared_examples "send payment_reminder" do
    it "send payment_reminder" do
      visit "/admin/payments"
      find("tr", text: booking.number).first("td").click

      within "fieldset", text: "Zahlungserinnerung versenden" do
        click_on "versenden"
      end
      expect(page).to have_flash "success", "Nachricht wird in Kürze versendet"
      expect(page).to have_no_content "Bitte warten, Daten werden geladen"

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq "#{booking.number}: Zahlungshinweis - Intervilla"
      expect(mail.body.decoded).to include curr_values.lookup_value(
        "Mietkosten inkl. Kaution",
        format_options: { delimiter: "'", format: "%n" },
      ) # Vermutlich ein geschütztes Leerzeichen zwischen € und Zahl
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, start_date: Date.current

    include_examples "send payment_reminder"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, start_date: Date.current

    include_examples "send payment_reminder"
  end
end
