module FullBookingHelper
  include ActionView::Helpers::NumberHelper
  include PriceHelper

  module_function

  extend FactoryBot::Syntax::Methods

  def create_full_booking( # rubocop:disable Metrics/ParameterLists
    villa:        nil,
    start_date:   41.days.from_now,
    end_date:     start_date + 7.days,
    with_owner:   false,
    with_manager: false,
    adults:       2,
    currency:     Currency::EUR,
    villa_name:   nil,
    boat_state:   nil
  )
    Currency.with(currency) do
      villa_inquiry = create_villa_inquiry(villa:, start_date:, end_date:, with_owner:, with_manager:, adults:, currency:, villa_name:, boat_state:)

      yield villa_inquiry if block_given?

      booking = create(:booking, inquiry: villa_inquiry.inquiry, state: "booked")
      booking
    end
  end

  def create_full_booking_with_boat( # rubocop:disable Metrics/ParameterLists
    villa:             nil,
    start_date:        41.days.from_now,
    end_date:          start_date + 7.days,
    with_owner:        false,
    with_manager:      false,
    currency:          Currency::EUR,
    with_boat_manager: false,
    boat_state:        :inclusive
  )
    Currency.with(currency) do
      create_full_booking(villa:, start_date:, end_date:, with_owner:, with_manager:, currency:, boat_state:) do |vi|
        create_boat_inquiry(villa_inquiry: vi, with_boat_manager:, with_owner:, currency:)
      end
    end
  end

  # TODO: durch factory ersetzen? -> default-werte übernehmen
  def create_villa_inquiry( # rubocop:disable Metrics/ParameterLists
    villa:        nil,
    start_date:   41.days.from_now,
    end_date:     start_date + 7.days,
    with_owner:   false,
    with_manager: false,
    currency:     Currency::EUR,
    adults:       2,
    villa_name:   nil,
    boat_state:   nil
  )
    Currency.with(currency) do
      villa_traits = %i[bookable]
      villa_traits << :with_owner if with_owner
      villa_traits << :with_manager if with_manager

      if boat_state.present?
        villa_boat_trait = boat_state == :optional ? :with_optional_boat : :with_mandatory_boat
        villa_traits << villa_boat_trait
      end

      villa_traits << { name: villa_name } if villa_name

      villa ||= create(:villa, *villa_traits)

      inquiry = create(:inquiry, currency:)

      create(:villa_inquiry, inquiry:, villa:, start_date:, end_date:, adults:).tap { _1.inquiry.reload }
    end
  end

  def create_reservation(
    villa:      nil,
    start_date: Date.current,
    end_date:   start_date + 7.days,
    currency:   Currency::EUR
  )
    i = create_villa_inquiry(villa:, start_date:, end_date:, currency:).inquiry
    Reservation.create!(inquiry: i)
  end

  # Bootsbuchung zur zeit nur in Kombination mit Villa
  def create_boat_inquiry(
    villa_inquiry: create(:villa_inquiry, :villa_with_optional_boat),
    with_boat_manager: false,
    with_owner: false,
    currency: Currency::EUR
  )
    Currency.with(currency) do
      villa = villa_inquiry.villa

      boat         = villa.inclusive_boat || villa.optional_boats.first
      boat.manager = create :contact if with_boat_manager
      boat.owner ||= villa.owner if with_owner
      boat.save!

      create :boat_inquiry,
        boat:,
        inquiry:    villa_inquiry.inquiry,
        start_date: villa_inquiry.start_date + 1.day,
        end_date:   villa_inquiry.end_date - 1.day
    end
  end

  def create_boat_for_villa(villa, *traits)
    boat = create(:boat, :with_prices, *traits)
    villa.optional_boats << boat
    villa.reload
    boat
  end

  def create_booking_request(inquiry_params = {})
    reset_email
    visit villa_path(villa)

    date_range_picker.wait
    s = inquiry_params[:start_date]
    e = inquiry_params[:end_date]
    date_range_picker.select_dates(s, e, confirm: false)
    expect(page).to have_content format("%d Nächte", e.to_date - s.to_date)

    {
      adults:            [2,   "Anzahl Erwachsene"],
      children_under_6:  [nil, "Anzahl Kinder bis 6 Jahre"],
      children_under_12: [nil, "Anzahl Kinder bis 12 Jahre"],
    }.each do |param, (fallback, selector)|
      n = inquiry_params[param] || fallback
      fill_in selector, with: n if n
    end

    using_wait_time Capybara.default_max_wait_time do
      yield if block_given?
    end

    click_on "unverbindlich anfragen" # Seitenwechsel!
    expect(page).to have_no_css "#reservation-form.villa-reservation-form"

    Inquiry.order(created_at: :desc).first
  end

  def create_owner_clearing(currency: Currency::EUR, summary_on: Date.current.beginning_of_month, villa: nil)
    other = create_full_booking(with_owner: true, with_manager: true, currency:, villa:)
    other.update(summary_on:)
    create :villa_billing, villa_inquiry: other.villa_inquiry
  end

  def create_customer(newsletter: false)
    select customer_params[:title], from: "Anrede"

    fill_in "Vorname", with: customer_params[:first_name]
    fill_in "Nachname", with: customer_params[:last_name]

    ["E-Mail-Adresse", "Bitte bestätigen Sie Ihre E-Mail-Adresse"].each do |f|
      fill_in f, with: customer_params[:email]
    end

    check "Ich möchte mich für den Newsletter anmelden" if newsletter

    fill_in "Telefon", with: "0815"

    click_on "Anfrage absenden"
    expect(page).to have_content "Vielen Dank"
  end

  def confirm_booking_request(inquiry, customer_params:)
    visit new_booking_path(token: inquiry.token)
    confirm_booking_request_on_page(inquiry, customer_params:)

    if inquiry.immediate_payment_required?
      expect(page).to have_current_path payments_path(inquiry.token), ignore_query: true
      fake_bsp1_payment(inquiry.reservation)
    end
    expect(page).to have_content "Vielen Dank für Ihre Buchung und Ihr Vertrauen!"
  end

  def confirm_booking_request_on_page(inquiry, customer_params:, button_text: "Jetzt buchen") # rubocop:disable Metrics/MethodLength
    customer = inquiry.customer
    within "form#new_booking" do
      expect(page).to have_field "Vorname", disabled: true, with: customer.first_name
      expect(page).to have_field "Nachname", disabled: true, with: customer.last_name
    end

    fill_in "Straße", with: customer_params[:address]
    fill_in "Hausnummer", with: customer_params[:appnr]
    fill_in "Postleitzahl", with: customer_params[:postal_code]
    fill_in "Ort", with: customer_params[:city]
    select "Deutschland", from: "Land"
    select "Bremen", from: "Bundesland"

    within "fieldset", text: "Reisende" do
      all(".panel").each do |panel|
        panel.fill_in "Vorname", with: Faker::Name.first_name
        panel.fill_in "Nachname", with: Faker::Name.last_name

        within panel do
          date_range_picker.select_dates 35.years.ago
        end
      end
    end
    check "booking_agb"
    choose "booking_customer_attributes_travel_insurance_insured"

    click_on button_text
  end
end

RSpec.configure do |c|
  c.include FullBookingHelper
end
