require "rails_helper"

RSpec.describe "Villas" do
  specify "index", vcr: { cassette_name: "villa/geocode" } do
    villas = 2.times.map { |n|
      create(:villa, :bookable, name: "villa #{n}")
    }
    visit de_villas_path

    2.times do |n|
      expect(page).to have_content "villa #{n}"
      expect(page).to have_content "1'120,00"
      expect(page).to have_content "inklusive 2 Personen / pro Woche"

      path = de_villa_path(villas[n])
      expect(page).to have_css "a[href='#{path}']"
    end
  end
end
