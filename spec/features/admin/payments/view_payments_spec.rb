require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "view payments" do
    specify "view payments" do
      visit "/admin/payments"

      within "thead" do
        ["Buchung/Mieter", "Anzahlung", "Gesamtbetrag", "Zahlungseingang", "Differenz"].each do |header|
          expect(page).to have_content header
        end
      end

      within "tbody" do
        expect(page).to have_content booking.number
        expect(page).to have_content booking.customer.to_s
        expect(page).to have_content curr_values.lookup_value("Mietkosten inkl. Kaution", format_options: OdsTestValues::RAILS_CURRENCY_FORMAT)
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR

    include_examples "view payments"
  end

  context "USD" do
    include_context "editable booking", Currency::USD

    include_examples "view payments"
  end
end
