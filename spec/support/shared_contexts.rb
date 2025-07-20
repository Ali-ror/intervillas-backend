RSpec.shared_context "a full booking" do
  let(:villa) { create(:villa, :bookable) }
  let(:inquiry) { create(:inquiry) }
  let!(:villa_inquiry) { create(:villa_inquiry, inquiry: inquiry, villa: villa) }
  let(:booking) { create(:booking, inquiry: inquiry, state: "booked") }
end

RSpec.shared_context "gap" do
  let(:today) {
    # Code Smell: Hier der Weihnachtszeit explizit aus dem Weg gehen,
    # weil die MINIMUM_BOOKING_NIGHTS in Abhängigkeit von Weihnachten
    # variieren.
    d = Date.current
    d.month == 12 ? d + 1.month : d
  }
  let!(:villa) { create(:villa, :bookable) }
  let(:min_gap) { VillaInquiry.minimum_booking_nights(today) }
  let(:gap) { min_gap }
end

RSpec.shared_context "as_admin" do
  let(:admin) { create(:user, :with_password, :with_second_factor, admin: true) }

  before do
    sign_in admin, scope: :user
  end
end

RSpec.shared_context "as_manager" do
  let!(:manager) { sign_in_manager }
end

RSpec.shared_context "prepare billings" do
  let(:villa_owner) { create :contact }
  let(:boat_owner) { nil }
  let(:boat_optional) { true }

  let(:villa) {
    traits = [
      :bookable,
      (boat_optional ? :with_optional_boat : :with_mandatory_boat),
    ]
    create :villa, *traits, owner: villa_owner
  }
  let(:boat) {
    if boat_owner
      b       = boat_optional ? villa.optional_boats.first : villa.inclusive_boat
      b.owner = boat_owner
      b.tap(&:save!)
    end
  }

  let(:start_date) { Date.current }
  let(:end_date)   { start_date + 7.days }
  let(:external)   { false }
  let(:currency)   { Currency::EUR }

  let(:inquiry) { create :inquiry, external: external, currency: currency }
  let(:booking) { external ? inquiry.booking : create(:booking, inquiry: inquiry, state: "booked") }
  let(:villa_inquiry) { create :villa_inquiry, inquiry: inquiry, villa: villa, start_date: start_date, end_date: end_date }
  let(:boat_inquiry) {
    if boat_owner
      create(:boat_inquiry, inquiry: inquiry, boat: boat, start_date: start_date + 1.day, end_date: end_date - 1.day)
    end
  }

  before do
    energy_price  = 0.12
    energy_price *= Setting.exchange_rate_usd if external

    create(:villa_billing, villa_inquiry: villa_inquiry, energy_price: energy_price)
    create(:boat_billing, boat_inquiry: boat_inquiry) if boat_owner
  end
end

def make_legacy_prices(inquiry, adults:)
  inquiry.clearing_items.where(category: "base_rate").first.update!(
    category: "adults",
    amount:   adults,
    price:    curr_values.single_rate(occupancy: adults, format: false),
  )
  inquiry.clearing_items.where(category: "additional_adult").delete_all
  inquiry.clearing_items.reload
  inquiry.clearing_items = Currency.with(inquiry.currency) { inquiry.villa_inquiry.clearing_builder.clearing_items }
  inquiry.save!
  inquiry.clearing_items.reload
end

RSpec.shared_context "editable booking" do |curr, adults: 2, nights: 7, start_date: 41.days.from_now, villa_name: nil, legacy_prices: false, boat_state: nil| # rubocop:disable Metrics/ParameterLists
  include_context "TestValues", curr

  let!(:booking) {
    create_full_booking(
      with_owner:   true,
      with_manager: true,
      currency:     curr,
      adults:       adults,
      start_date:   start_date,
      end_date:     start_date + nights.days,
      villa_name:   villa_name,
      boat_state:   boat_state,
    )
  }
  let(:villa_inquiry) { booking.villa_inquiry }

  if legacy_prices
    before do
      make_legacy_prices(booking.inquiry, adults: adults)
    end
  end
end

RSpec.shared_context "editable booking with boat" do |curr, state: :optional, legacy_prices: false|
  include_context "editable booking", curr, legacy_prices: legacy_prices, boat_state: state

  let!(:boat_inquiry) {
    create_boat_inquiry(
      villa_inquiry: villa_inquiry,
      with_owner:    true,
      currency:      curr,
    )
  }
end

RSpec.shared_context "TestValues" do |curr|
  let(:curr_values) { OdsTestValues.for(curr) }
  let(:curr) { curr }

  before { switch_to_usd } if curr == Currency::USD

  after { Currency.reset! }
end

RSpec.shared_context "prepare new booking" do |curr|
  # Die Zeitreise hier dient dazu die Mindestbuchungsdauer um Weihnachten
  # herum auszuhebeln
  around do |ex|
    Timecop.travel Date.new(Date.current.year + 1, 9, 3), &ex
  end

  include_context "offers", curr
end

RSpec.shared_context "offers" do |curr|
  let(:customer_params) { attributes_for :customer }
  let(:villa_inquiry_params) { attributes_for :villa_inquiry }

  include_context "TestValues", curr
end

RSpec.shared_context "diverse travel dates" do
  delegate :start_date, :end_date, to: :villa_inquiry

  let(:early_leave) { end_date - 2.days }
  let(:late_arrival) { start_date + 2.days }
end

RSpec.shared_context "villa_inquiry" do |curr, legacy_prices: false|
  include_context "TestValues", curr

  let!(:villa_inquiry) { create_villa_inquiry(currency: curr) }

  if legacy_prices
    before do
      make_legacy_prices(villa_inquiry.inquiry, adults: 2)
    end
  end
end

RSpec.shared_context "high season" do
  let(:high_season) {
    create :high_season,
      villas:     [villa_inquiry.villa],
      created_at: 1.year.ago,
      starts_on:  villa_inquiry.start_date - 1.month,
      ends_on:    villa_inquiry.end_date + 1.month
  }

  before do
    # simulate the inquiry being created *after* the high season has
    # already existed, by retroactively creating a matching disount
    villa_inquiry.inquiry.discounts.create! \
      inquiry_kind: "villa",
      subject:      "high_season",
      value:        high_season.addition,
      period:       high_season.date_range

    Currency.with(villa_inquiry.inquiry.currency) do
      villa_inquiry.refresh_clearing_items
    end
  end
end
