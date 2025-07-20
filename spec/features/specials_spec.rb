require "rails_helper"

RSpec.feature "Specials" do
  # Angebot mit Buchung für die Angebotsvilla
  let!(:villa) { create :villa, :bookable }
  let!(:booking) { create_full_booking villa: villa }
  let!(:special) { create :special, villas: [villa] }

  scenario do
    visit root_path

    expect(page).to have_link villa.name

    within first(".navbar-nav") do
      click_link "Last Minute"
    end

    within ".room-grid" do
      expect(page).to have_link villa.name
    end
  end
end
