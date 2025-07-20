require "rails_helper"

RSpec.feature "new booking including optional boat", :js, vcr: { cassette_name: "admin_villa/geocode" } do
  include_context "as_admin"

  shared_examples "with optional boat selected" do
    let!(:villa) { create :villa, :with_optional_boat, :with_descriptions, :bookable }
    let!(:boat_a) { villa.optional_boats.first }
    let(:boat_b) { create_boat_for_villa villa, :with_utilities, owner: create(:contact) }
    let(:boat_c) { create_boat_for_villa villa, :with_utilities }

    before do
      # Preise anpassen
      boat_b.prices.destroy_all
      %w[training deposit].each do |subject|
        create :boat_price, boat: boat_b, subject: subject, value: 40.0
      end
      create :boat_price, boat: boat_b, subject: "daily", amount: 3, value: 45.0
      create :boat_price, boat: boat_b, subject: "daily", amount: 6, value: 50.01

      # boat_c überlappend anderweitig vermieten
      v = create(:villa, :bookable)
      i = create(:inquiry)
      e = villa_inquiry_params[:end_date]
      create :villa_inquiry,
        inquiry:    i,
        villa:      v,
        start_date: e - 3.days,
        end_date:   e + 8.days
      create :boat_inquiry,
        inquiry:    i,
        boat:       boat_c,
        start_date: e - 2.days,
        end_date:   e + 7.days
      create :booking,
        inquiry: i,
        state:   "booked"
    end

    it "creates booking" do
      inquiry = create_booking_request(villa_inquiry_params) {
        within_price_table { click_on "Details anzeigen" }
        expect_price_breakdown_lookup("Grundpreis für 2 Pers.", "14 Nächte Grundpreis")
      }

      click_on "Boote anzeigen"

      within ".room-grid" do
        expect(page).to have_content boat_a.display_name
        expect(page).to have_content boat_b.display_name
        expect(page).to have_content boat_c.display_name
        click_on boat_a.display_name
      end

      within(".v--modal") { click_on "Boot auswählen" }
      expect(page).to have_selector "h2.lined-heading", text: boat_a.display_name # selected boat

      within_price_table { click_on "Details anzeigen" }
      date_range_picker.within_widget do |drp|
        drp.click_date villa_inquiry_params[:start_date] + 1.day
        drp.click_date villa_inquiry_params[:end_date] - 1.day
      end

      expect_price_breakdown_lookup("Boot-Anlieferung", "Boot-Anlieferung")
      expect_price_breakdown_lookup("Bootsmiete", "13 Tage 1 Boot")

      within(".room-grid") { click_on boat_b.display_name }
      within(".v--modal") { click_on "Boot auswählen" }
      expect(page).to have_selector "h2.lined-heading", text: boat_b.display_name # selected boat changed

      expect_price_breakdown_lookup("Boot-Anlieferung", "Boot-Anlieferung", :alternative_boat)
      expect_price_breakdown_lookup("Bootsmiete", "13 Tage 1 Boot", :alternative_boat)

      date_range_picker.select_dates \
        villa_inquiry_params[:start_date] + 1.day,
        villa_inquiry_params[:end_date] - 3.days
      expect_price_breakdown_lookup("Bootsmiete", "11 Tage 1 Boot", :alternative_boat)

      click_on "unverbindlich anfragen"
      create_customer
      inquiry.reload
      expect(page).to have_content I18n.t("bookings.create.vielen_dank")
      confirm_booking_request(inquiry, customer_params: customer_params)
      inquiry.reload

      inquiry.travelers.each do |t|
        expect(t.born_on).to be_present
      end

      expect(inquiry.boat_inquiry).to be_present
      click_on "zur Buchungsbestätigung"
      expect(open_email(boat_b.owner.emails.first)).to be_present
    end
  end

  context "in EUR" do
    include_context "prepare new booking", Currency::EUR
    include_examples "with optional boat selected"
  end

  context "in USD" do
    include_context "prepare new booking", Currency::USD
    include_examples "with optional boat selected"
  end
end
