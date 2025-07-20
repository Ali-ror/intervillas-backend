require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  include_context "editable booking", Currency::EUR, legacy_prices: true

  feature "Kundendaten" do
    let(:customer) { booking.inquiry.customer }
    let(:customer_params) { attributes_for :customer }

    scenario do
      visit admin_bookings_path

      within "tr.booking", text: booking.number do
        click_on "bearbeiten"
      end
      click_on "Kunde"

      expect(page).to have_field "Vorname", with: customer[:first_name]

      select customer_params[:title], from: "Anrede"
      fill_in "Vorname", with: customer_params[:first_name]
      fill_in "Nachname", with: customer_params[:last_name]
      fill_in "E-Mail-Adresse", with: customer_params[:email]
      fill_in "Straße", with: customer_params[:address]
      fill_in "Hausnummer", with: customer_params[:appnr]
      fill_in "Postleitzahl", with: customer_params[:postal_code]
      fill_in "Ort", with: customer_params[:city]

      click_on "Kunde speichern"

      expect(page).to have_flash "success", "Kundendaten erfolgreich gespeichert"
      expect(page).to have_css ".nav-pills li", text: "Kunde (#{customer_params[:first_name]} #{customer_params[:last_name]})"
      expect(page).to have_field "Straße", with: customer_params[:address]
    end
  end
end
