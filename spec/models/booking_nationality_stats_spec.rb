require "rails_helper"

RSpec.describe BookingNationalityStats do
  describe "stellt Statistiken zur Nationalität (Adresse) aller Buchungen eines Jahres bereit" do
    def create_bookings(count, country)
      count.times do
        customer = create :customer, country: country
        inquiry  = create :inquiry, :with_villa_inquiry, customer: customer, start_date: Date.new(2019, 7, 1)
        create :booking, inquiry: inquiry
      end
    end

    subject(:stats) { described_class.nationalities }

    before do
      create_bookings 6, "DE"
      create_bookings 3, "US"
      create_bookings 1, "CH"
    end

    it "stellt alle Nationalitäten zur Verfügung" do
      expect(stats).to include have_attributes(country: "DE", n: 6)
      expect(stats).to include have_attributes(country: "US", n: 3)
      expect(stats).to include have_attributes(country: "CH", n: 1)
    end

    it "liefert für ein Jahr und Nationalität den Prozentualen Anteil zu alles Buchungen des Jahres" do
      {
        "DE" => 0.6,
        "US" => 0.3,
        "CH" => 0.1,
      }.each do |country, expected_share|
        stat = stats.find { |s| s.country == country }
        expect(stat.share_in_year(2019)).to eq expected_share
      end
    end
  end
end
