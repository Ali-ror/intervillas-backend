require "rails_helper"

RSpec.describe "Angebote", :js do
  include_context "as_admin"

  let(:customer_params) { attributes_for :customer }

  let!(:inquiry) { create_villa_inquiry.inquiry }

  scenario "löschen" do
    visit edit_admin_inquiry_path(inquiry)
    expect(page).to have_no_content "Bitte warten, Daten werden geladen"
    expect(page).to have_no_css "#price_table.refreshing"

    click_on "löschen"
    expect(page).to have_content "Angebot #{inquiry.number} wurde gelöscht"

    expect { inquiry.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario "buchen", :vcr do
    visit edit_admin_inquiry_path(inquiry)

    click_on "Buchung abschließen"

    confirm_booking_request_on_page(inquiry, customer_params: customer_params)
    expect(page).to have_content "Vielen Dank für Ihre Buchung und Ihr Vertrauen!"
    expect(inquiry.reload.booking).to be_present
  end
end
