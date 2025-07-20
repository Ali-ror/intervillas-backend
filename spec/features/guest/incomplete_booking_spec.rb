require "rails_helper"

RSpec.feature "incomplete booking", :js, vcr: { cassette_name: "admin_villa/geocode" } do
  let!(:villa)          { create :villa, :with_descriptions, :bookable, :with_geocode }
  let(:customer_params) { attributes_for :customer }

  it "form presents error message" do
    inquiry = Date.current.year.then { |y|
      create_booking_request({
        start_date: Date.new(y + 1, 8, 12),
        end_date:   Date.new(y + 1, 8, 21),
      })
    }
    create_customer
    visit new_booking_path(token: inquiry.reload.token)

    confirm_booking_request_on_page inquiry,
      customer_params: customer_params.except(:appnr, :city)

    %w[Hausnummer Ort].each do |field|
      within ".form-group.has-error", text: field do
        expect(page).to have_content "muss ausgefüllt werden"
      end
    end

    confirm_booking_request_on_page(inquiry, customer_params:)
    expect(page).to have_content "Vielen Dank für Ihre Buchung"
  end
end
