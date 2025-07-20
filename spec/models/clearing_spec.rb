require "rails_helper"

RSpec.describe Clearing do
  shared_examples "included Boat Prices" do
    describe "Boat Prices" do
      let(:boat_clearing) { clearing.for_rentable(:boat) }

      it { expect(boat_clearing.rents).to be_empty }

      it { expect(boat_clearing.utilities).to include kind_of(ClearingItem) }
      it { expect(boat_clearing.utilities).to include have_attributes(category: "training", total: 150, amount: 1) }

      it { expect(boat_clearing.deposits).to include kind_of(ClearingItem) }
      it { expect(boat_clearing.deposits).to include have_attributes(boat_id: kind_of(Integer), category: "deposit", total: 900, amount: 1) }
    end
  end

  shared_examples "House Prices" do
    describe "House Prices" do
      let(:villa_clearing) { clearing.for_rentable(:villa) }

      it { expect(villa_clearing.rents).to include kind_of(ClearingItem) }
      it { expect(villa_clearing.rents).to include have_attributes(category: "base_rate", total: 1280, amount: 1) }
      it { expect(villa_clearing.rents).not_to include have_attributes(category: "children_under_6") }
      it { expect(villa_clearing.rents).not_to include have_attributes(category: "children_under_12") }

      it { expect(villa_clearing.utilities).to include kind_of(ClearingItem) }
      it { expect(villa_clearing.utilities).to include have_attributes(category: "cleaning", total: 42.42, amount: 1) }

      it { expect(villa_clearing.deposits).to include kind_of(ClearingItem) }
      it { expect(villa_clearing.deposits).to include have_attributes(villa_id: kind_of(Integer), category: "deposit", total: 42.42, amount: 1) }
    end
  end

  shared_examples "optional Boat Prices" do
    describe "Boat Prices" do
      let(:boat_clearing) { clearing.for_rentable(:boat) }

      it { expect(boat_clearing.rents).to include kind_of(ClearingItem) }
      it { expect(boat_clearing.rents).to include have_attributes(category: "price", total: 162.61, time_units: 7) }

      it { expect(boat_clearing.utilities).to include kind_of(ClearingItem) }
      it { expect(boat_clearing.utilities).to include have_attributes(category: "training", total: 150, amount: 1) }

      it { expect(boat_clearing.deposits).to include kind_of(ClearingItem) }
      it { expect(boat_clearing.deposits).to include have_attributes(boat_id: kind_of(Integer), category: "deposit", total: 900, amount: 1) }
    end
  end

  let!(:villa) { create :villa, :bookable }

  describe ".from_inquiry" do
    subject(:clearing) { inquiry.clearing }

    context "8 days" do
      # 2 Erwachsene / 8 Tage
      let(:inquiry) { create_villa_inquiry(villa: villa, start_date: Date.current + 2.days, end_date: Date.current + 10.days).inquiry }

      context "House without Boat" do
        it { expect(clearing.rentable_clearings.size).to eq 1 }

        include_examples "House Prices"
      end

      context "House with optional Boat not selected" do
        let(:villa) { create :villa, :with_optional_boat, :bookable }

        it { expect(clearing.rentable_clearings.size).to eq 1 }

        include_examples "House Prices"
      end
    end

    context "8 days with boat" do
      # 2 Erwachsene / 8 Tage

      context "House with Boat included" do
        let(:inquiry) { create :inquiry, :with_villa_inquiry, :with_mandatory_boat }

        it { expect(clearing.rentable_clearings.size).to eq 2 }

        include_examples "House Prices"

        include_examples "included Boat Prices"
      end

      context "House with optional Boat" do
        let(:inquiry) { create :inquiry, :with_villa_inquiry, :with_optional_boat }

        it { expect(clearing.rentable_clearings.size).to eq 2 }

        include_examples "House Prices"

        include_examples "optional Boat Prices"
      end
    end
  end

  describe ".from_villa" do
    subject(:clearing) { Clearing.build(villa_params) }

    let(:villa_params) do
      Clearing::VillaParams.new.tap do |vp|
        vp.villa = villa

        params.each do |k, v|
          vp.send "#{k}=", v
        end
      end
    end

    let(:start_date) { 1.month.from_now.to_date }

    context "House with Discount" do
      let!(:villa_addition) { create :holiday_discount, :christmas, villa: villa }
      let(:start_date) { christmas - 5.days }
      let(:christmas) { Date.parse("2015-12-25") }

      let(:params) do
        {
          adults:     2,
          start_date: start_date,
          end_date:   (start_date + 11.days).to_date,
        }
      end

      let(:house_prices) { clearing.for_rentable(:villa) }

      it { expect(clearing.rentable_clearings.size).to eq 1 }

      it { expect(house_prices.rents).to include kind_of(ClearingItem) }

      it { expect(house_prices.rents).to include have_attributes(category: "base_rate", total: 1760, amount: 1, time_units: 11) }
      it { expect(house_prices.rents).to include have_attributes(category: "base_rate_christmas", total: 224, amount: 1, time_units: 7) }
      it { expect(house_prices.rents).not_to include have_attributes(category: "children_under_6") }
      it { expect(house_prices.rents).not_to include have_attributes(category: "children_under_12") }

      it { expect(house_prices.utilities).to include kind_of(ClearingItem) }
      it { expect(house_prices.utilities).to include have_attributes(category: "cleaning", total: 42.42, amount: 1) }

      it { expect(house_prices.deposits).to include kind_of(ClearingItem) }
      it { expect(house_prices.deposits).to include have_attributes(villa_id: kind_of(Integer), category: "deposit", total: 42.42, amount: 1) }
    end

    context "House without Boat" do
      let(:params) do
        {
          adults:     2,
          start_date: start_date,
          end_date:   (start_date + 8.days).to_date,
        }
      end

      it { expect(clearing.rentable_clearings.size).to eq 1 }

      include_examples "House Prices"
    end

    context "House with Boat included" do
      let(:villa) { create :villa, :with_mandatory_boat, :bookable }
      let(:params) do
        {
          adults:     2,
          start_date: start_date,
          end_date:   (start_date + 8.days).to_date,
        }
      end

      it { expect(clearing.rentable_clearings.size).to eq 2 }

      include_examples "House Prices"
      include_examples "included Boat Prices"
    end

    context "House with optional Boat" do
      subject(:clearing) { Clearing.build(villa_params).update(nil, boat_params, nil) }

      let(:villa) { create :villa, :with_optional_boat, :bookable }

      let(:villa_params) do
        Clearing::VillaParams.new.tap do |vp|
          vp.villa      = villa
          vp.adults     = 2
          vp.start_date = start_date
          vp.end_date   = start_date + 8.days
        end
      end

      let(:boat_params) do
        Clearing::BoatParams.new.tap do |bp|
          bp.start_date = start_date + 1.day
          bp.end_date   = start_date + 7.days
          bp.boat       = villa.optional_boats.first
        end
      end

      it { expect(clearing.rentable_clearings.size).to eq 2 }

      include_examples "House Prices"
      include_examples "optional Boat Prices"
    end

    context "House with optional Boat not selected" do
      let(:villa) { create :villa, :with_optional_boat, :bookable }
      let(:params) do
        {
          adults:     2,
          start_date: start_date,
          end_date:   start_date + 8.days,
        }
      end

      it { expect(clearing.rentable_clearings.size).to eq 1 }

      include_examples "House Prices"
    end
  end

  describe ".from_boat" do
    subject(:clearing) { Clearing.new([]).update(nil, boat_params, nil) }

    let(:boat) { create :boat, :with_prices }

    context "without holiday_discount" do
      let(:start_date) { 1.month.from_now.to_date }

      let(:boat_params) do
        Clearing::BoatParams.new.tap do |bp|
          bp.start_date = start_date
          bp.end_date   = start_date + 6.days
          bp.boat       = boat
        end
      end

      it { expect(clearing.rentable_clearings.size).to eq 1 }

      include_examples "optional Boat Prices"
    end

    context "with holiday_discount" do
      let!(:boat_addition) { create :holiday_discount, :christmas, boat: boat }
      let(:start_date) { christmas - 5.days }
      let(:christmas) { Date.parse("2015-12-25") }

      let(:boat_params) do
        Clearing::BoatParams.new.tap do |bp|
          bp.start_date = start_date
          bp.end_date   = start_date + 11.days
          bp.boat       = boat
        end
      end

      let(:boat_prices) { clearing.for_rentable(:boat) }

      it { expect(clearing.rentable_clearings.size).to eq 1 }

      it { expect(boat_prices.rents).to include kind_of(ClearingItem) }
      it { expect(boat_prices.rents).to include have_attributes(category: "price", total: 278.76, time_units: 12) }
      it { expect(boat_prices.rents).to include have_attributes(category: "price_christmas", total: 37.168, time_units: 8) }

      it { expect(boat_prices.total_rents).to eq 315.928 }

      it { expect(boat_prices.utilities).to include kind_of(ClearingItem) }
      it { expect(boat_prices.utilities).to include have_attributes(category: "training", total: 150, amount: 1) }
    end
  end
end
