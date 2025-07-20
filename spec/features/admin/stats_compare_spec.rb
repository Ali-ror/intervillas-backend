require "rails_helper"

RSpec.feature "Belegungsstatistiken", :js do
  let!(:villa) { create :villa, :bookable }

  include_context "as_admin"

  before do
    create_full_booking villa: villa, start_date: Date.new(2018, 1, 1)
    create_full_booking villa: villa, start_date: Date.new(2019, 1, 1), end_date: Date.new(2019, 1, 15)
    create_full_booking villa: villa, start_date: Date.new(2019, 1, 15), end_date: Date.new(2019, 1, 22)
  end

  def within_row(name, &block)
    within "tr", text: name, &block
  end

  scenario do
    visit "admin/stats/compare"
    select villa.name, from: "Villa auswählen"
    select "2018-2019", from: "Jahre vergleichen"

    expect(page).to have_content "Belegungsstatistiken #{villa.name}"

    expect(page).to have_css "th", text: "Januar"
    expect(page).to have_css "th", text: "2018"
    expect(page).to have_css "th", text: "2019"
    expect(page).to have_css "th", text: "Veränderung"

    within "table", text: "Januar" do
      within_row "Anz. Anfragen" do
        expect(page).to have_content "1 2 +1"
      end
    end
  end
end
