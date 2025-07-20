require "rails_helper"

RSpec.feature "externe Buchung" do
  include_context "as_admin"
  include_context "offers", Currency::EUR

  let!(:villa) { create :villa, :bookable, :with_owner }

  it "erstellt externe Buchung" do
    navigate_to_inquiry_create
    check "externe Buchung"
    enter_house_data curr, curr_values

    expect(page).to have_content "Externe Buchung"

    expect {
      create_billing
      expect(page).to have_content "Abrechnung gespeichert"
    }.to change(VillaBilling, :count).by(1)

    click_on "Buchungen"
    click_on "Summaries"
    click_on "anzeigen"

    number = VillaBilling.last.inquiry.number
    expect(number).to match(/^IV-E\d+$/)
    expect(page).to have_selector "tr", text: number
  end
end
