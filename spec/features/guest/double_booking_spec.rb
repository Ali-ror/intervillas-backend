require "rails_helper"

RSpec.feature "avoiding double-booking", :js, vcr: { cassette_name: "admin_villa/geocode" } do
  let!(:villa) { create :villa, :with_descriptions, :bookable, :with_geocode }

  let(:curr_values) { OdsTestValues.for(Currency::EUR) }

  context "on overlapping date ranges" do
    let(:y)               { Date.current.year }
    let(:villa_inquiry_a) { { start_date: Date.new(y + 1, 8, 12), end_date: Date.new(y + 1, 8, 21) } } # avoid holidays
    let(:villa_inquiry_b) { { start_date: villa_inquiry_a[:end_date] - 5, end_date: villa_inquiry_a[:end_date] + 5 } }
    let(:customer_params) { attributes_for :customer }

    def create_inquiry(params)
      create_booking_request(params).tap {
        create_customer
      }.reload
    end

    # Die Zeitreise hier dient dazu die Mindestbuchungsdauer um Weihnachten
    # herum auszuhebeln
    around do |ex|
      Timecop.travel Date.new(Date.current.year + 1, 9, 3), &ex
    end

    scenario "with two tenants" do
      inquiry = create_inquiry(villa_inquiry_a)
      visit new_booking_path(token: inquiry.token)

      using_ephemeral_session "second tenant" do
        confirm_booking_request(create_inquiry(villa_inquiry_b), customer_params: customer_params)
      end

      confirm_booking_request_on_page(inquiry, customer_params: customer_params)

      expect(page).to have_content "Ihre Wunschvilla wurde zwischenzeitlich von jemand anderem gebucht."
    end
  end
end
