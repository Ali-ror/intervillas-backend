require "rails_helper"

RSpec.feature "Last-Minute-Rabatt", :js do
  let(:villa) do
    create :villa, :displayable, :bookable
  end

  let!(:special) { create :special, villas: [villa] }

  let(:start_date) { special.start_date + 4.days }
  let(:end_date) { start_date + 20.days }
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
      expect(page).to have_content "20 Nächte"

      fill_in "Anzahl Erwachsene", with: 2

      within_price_table { click_on "Details anzeigen" }
      expect_price_breakdown_lookup("Grundpreis für 2 Pers.", "20 Nächte Grundpreis")
      expect_price_breakdown_lookup("Rabatt: Last Minute",    "10 Nächte - Last Minute")
      expect_price_breakdown_lookup("Mietpreis",              "Mietkosten", :last_minute)

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

      vi = VillaInquiry.last
      expect(vi.discounts).to include have_attributes \
        subject: "special",
        period:  (special.start_date...special.end_date + 1.day), # (a..b) != (a...b+1)
        value:   -special.percent

      expect(vi.clearing_items).to include have_attributes \
        amount:       1,
        category:     "base_rate_special",
        price:        curr_values.lookup_category(:base_rate_special, format: false),
        normal_price: curr_values.lookup_category(:base_rate_special, format: false),
        start_date:   start_date,
        end_date:     special.end_date

      expect(vi.clearing_items.where(category: "base_rate_special").count).to be 1
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
