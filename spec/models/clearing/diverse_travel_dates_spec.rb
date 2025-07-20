require "rails_helper"

RSpec.describe Clearing, "diverse travel dates" do
  context "Unterschiedliche Reisezeiträume" do
    subject(:clearing) { villa_inquiry.inquiry.clearing.update(villa_params, nil, villa_inquiry.inquiry) }

    let!(:villa_inquiry) { create_villa_inquiry }
    let(:late_arriving) { build_traveler "Kommt", "Später", arrives: 2.days }
    let(:early_leaving) { build_traveler "Geht", "Früher",  leaves: -2.days }
    let(:villa_params) do
      Clearing::VillaParams.new.tap do |vp|
        vp.villa     = villa_inquiry.villa
        vp.travelers = villa_inquiry.travelers + [late_arriving, early_leaving]
      end
    end
    let(:start_date) { villa_inquiry.start_date }
    let(:end_date)   { villa_inquiry.end_date }

    def build_traveler(first_name, last_name, arrives: nil, leaves: nil)
      Traveler.new \
        first_name:     first_name,
        last_name:      last_name,
        price_category: :adults,
        start_date:     arrives ? start_date + arrives : start_date,
        end_date:       leaves ? end_date + leaves : end_date
    end

    context "Hochsaison" do
      let(:high_season) {
        create :high_season,
          villas:     [villa_inquiry.villa],
          created_at: 1.year.ago,
          starts_on:  villa_inquiry.start_date - 1.day,
          ends_on:    villa_inquiry.end_date + 1.day
      }

      before do
        # simulate the inquiry being created *after* the high season has
        # already existed, by retroactively creating a matching disount
        villa_inquiry.inquiry.discounts.create! \
          inquiry_kind: "villa",
          subject:      "high_season",
          value:        high_season.addition,
          period:       high_season.date_range
      end

      it { expect(clearing.rents).to include have_attributes(category: "base_rate_high_season",        time_units: 2, amount: 1, price: 32) }
      it { expect(clearing.rents).to include have_attributes(category: "additional_adult_high_season", time_units: 2, amount: 1, price: 8) }
      it { expect(clearing.rents).to include have_attributes(category: "base_rate_high_season",        time_units: 3, amount: 1, price: 32) }
      it { expect(clearing.rents).to include have_attributes(category: "additional_adult_high_season", time_units: 3, amount: 2, price: 8) }
    end
  end
end
