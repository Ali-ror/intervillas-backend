require "rails_helper"

RSpec.feature "Angepasste Kaution", :js do
  let(:villa)       { create :villa, :bookable }
  let(:high_season) { create :high_season, villas: [villa], created_at: 1.year.ago }
  let(:inquiry)     { create(:inquiry, :with_villa_inquiry, start_date: high_season.starts_on, villa: villa) }
  let(:customer_params) { attributes_for :customer }

  scenario "Buchung ändert Kaution nicht", :vcr do
    # set different deposit
    deposit = inquiry.clearing_items.find_by(category: "deposit")
    expect(deposit.price).to be_within(0.0001).of(42.42)
    deposit.update! price: 23
    inquiry.clearing_items.reload

    visit new_booking_path(inquiry.token)
    confirm_booking_request_on_page(inquiry, customer_params: customer_params)
    expect(page).to have_content "Vielen Dank für Ihre Buchung"

    deposit = inquiry.clearing_items.find_by(category: "deposit")
    expect(deposit.price).to be_within(0.0001).of(23.0)
  end
end
