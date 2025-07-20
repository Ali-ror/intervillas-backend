require "rails_helper"

RSpec.feature "Feiertagsaufschlag", :js do
  let(:villa) { create :villa, :displayable, :with_optional_boat, :bookable }
  let(:boat) { villa.optional_boats.first }

  let(:year) { Time.current.year + 1 }
  let(:christmas) { Date.new year, 12, 25 }
  let(:start_date) { christmas - 5.days }
  let(:end_date) { christmas + 5.days }

  let(:customer_params) { attributes_for :customer }

  before do
    create :holiday_discount, :christmas, villa: villa
    create :holiday_discount, :christmas, boat: boat, created_at: 1.day.ago
  end

  around do |ex|
    Timecop.travel Date.new(year, 9, 3), &ex
  end

  shared_examples "Anfrage zur Weihnachtszeit" do
    scenario "Anfrage zur Weihnachtszeit", :vcr do
      visit root_path
      within first(".navbar-nav") do
        click_on "Ferienhaus Cape Coral"
      end
      click_on villa.name

      date_range_picker.wait
      date_range_picker.within_widget do |drp|
        drp.click_date start_date
        expect(page).to have_content "Die Mindestbuchungsdauer beträgt 14 Nächte."
        drp.click_date end_date
      end

      expect(page).to have_content "14 Nächte"

      # Mindestbuchungsdauer über Weihnachten wird enforciert
      date_range_picker.within_wrapper do
        expect(page).to have_no_content end_date.strftime("%d.%m.%Y")
        expect(page).to have_content (end_date + 4).strftime("%d.%m.%Y")
      end

      fill_in "Anzahl Erwachsene", with: 2

      within_price_table { click_on "Details anzeigen" }
      expect_price_breakdown_lookup("Grundpreis für 2 Pers.", "14 Nächte Grundpreis")
      expect_price_breakdown_lookup("Aufschlag: Weihnachten", "10 Nächte + Weihnachten")
      expect_price_breakdown_lookup("Mietpreis",              "Mietkosten", :christmas)

      click_on "unverbindlich anfragen"

      click_on "Boote anzeigen"
      click_on boat.display_name
      within(".v--modal") { click_on "Boot auswählen" }
      within_price_table do
        click_on "Details anzeigen"
        expect(page).to have_no_content "Boot"
        expect(page).to have_no_content "Boot-Anlieferung"
      end

      date_range_picker.within_widget do |drp|
        drp.click_date start_date + 1.day
        expect(page).to have_content "Die Mindestbuchungsdauer beträgt 3 Tage."
        drp.click_date end_date + 3.days
      end

      expect_price_breakdown_lookup("Bootsmiete",             "13 Tage 1 Boot",          within: "tbody.boat-clearing-details")
      expect_price_breakdown_lookup("Aufschlag: Weihnachten", "10 Tage 1 + Weihnachten", within: "tbody.boat-clearing-details")

      date_range_picker.select_dates(start_date + 2.days, end_date + 3.days) # doesn't change xmas surcharge
      expect_price_breakdown_lookup("Bootsmiete",             "12 Tage 1 Boot",          within: "tbody.boat-clearing-details")
      expect_price_breakdown_lookup("Aufschlag: Weihnachten", "10 Tage 1 + Weihnachten", within: "tbody.boat-clearing-details")

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

      # Boot mit Aufschlag
      expect(BoatInquiry.last.discounts).to include have_attributes \
        subject: "christmas",
        period:  (start_date + 2.days..end_date + 4.days),
        value:   20
    end
  end

  context "EUR" do
    include_context "TestValues", Currency::EUR
    include_examples "Anfrage zur Weihnachtszeit"
  end

  context "USD" do
    include_context "TestValues", Currency::USD
    include_examples "Anfrage zur Weihnachtszeit"
  end
end
