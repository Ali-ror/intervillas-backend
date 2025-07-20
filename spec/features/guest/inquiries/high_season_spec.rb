require "rails_helper"

RSpec.feature "Aufschlag zur Hochsaison", :js do
  let(:villa) do
    create :villa, :displayable, :bookable
  end

  let!(:high_season) { create :high_season, villas: [villa] }

  let(:start_date) { high_season.starts_on + 5.days }
  let(:end_date) { start_date + 14.days } # Mindestdauer in der Hochsaison sind 14 Nächte
  let(:customer_params) { attributes_for :customer }

  shared_examples "Anfrage" do
    scenario "Anfrage", :vcr do
      visit root_path
      within first(".navbar-nav") do
        click_on "Ferienhaus Cape Coral"
      end
      click_on villa.name

      date_range_picker.wait
      date_range_picker.select_dates(start_date, end_date, confirm: false)
      expect(page).to have_content "14 Nächte"
      fill_in "Anzahl Erwachsene", with: 2

      within_price_table { click_on "Details anzeigen" }
      expect_price_breakdown_lookup("Grundpreis für 2 Pers.", "14 Nächte Grundpreis")
      expect_price_breakdown_lookup("Aufschlag: Hochsaison",  "14 Nächte + Hochsaison")
      expect_price_breakdown_lookup("Mietpreis",              "Mietkosten", :high_season)

      click_on "unverbindlich anfragen"

      # Infos Reisende
      select customer_params[:title], from: "Anrede"
      fill_in "Vorname", with: customer_params[:first_name]
      fill_in "Nachname", with: customer_params[:last_name]
      fill_in "E-Mail-Adresse", with: customer_params[:email]
      fill_in "Bitte bestätigen Sie Ihre E-Mail-Adresse", with: customer_params[:email]
      fill_in "Telefon", with: customer_params[:phone]

      click_on "Anfrage absenden"
      expect(page).to have_content "Vielen Dank für Ihre Anfrage!"

      # Boot mit aufschlag
      expect(VillaInquiry.last.discounts).to include have_attributes \
        subject: "high_season",
        period:  (high_season.starts_on..high_season.ends_on + 1.day),
        value:   20
    end
  end

  context "EUR" do
    include_context "TestValues", Currency::EUR
    include_examples "Anfrage"
  end

  context "USD" do
    include_context "TestValues", Currency::USD
    include_examples "Anfrage"
  end
end
