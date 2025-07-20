require "rails_helper"

RSpec.describe Boat do
  %w[de_description].each do |col|
    it { is_expected.to validate_presence_of col }
  end

  it { is_expected.to belong_to(:exclusive_for_villa).optional }
  it { is_expected.to belong_to(:manager).optional }
  it { is_expected.to belong_to(:owner).optional }
  it { is_expected.to have_and_belong_to_many :optional_villas }

  it { is_expected.to have_many :images }
  it { is_expected.to have_many :prices }
  it { is_expected.to have_many :holiday_discounts }
  it { is_expected.to have_many :boat_inquiries }
  it { is_expected.to have_many :inquiries }
  it { is_expected.to have_many :bookings }
  it { is_expected.to have_many :blockings }

  describe ".exclusively_assignable" do
    subject(:exclusively_assignable_boats) { Boat.exclusively_assignable }

    let!(:exclusive_boat) { create :boat, :mandatory }
    let!(:assigned_boat) { create :boat, :assigned }
    let!(:exclusively_assignable_boat) { create :boat }

    it { expect(exclusively_assignable_boats).to include exclusively_assignable_boat }
    it { expect(exclusively_assignable_boats).not_to include exclusive_boat }
    it { expect(exclusively_assignable_boats).not_to include assigned_boat }
  end

  describe ".optionally_assignable" do
    subject(:optionally_assignable_boats) { Boat.optionally_assignable }

    let!(:exclusive_boat) { create :boat, :mandatory }
    let!(:assigned_boat) { create :boat, :assigned }
    let!(:optionally_assignable_boat) { create :boat }

    it { expect(optionally_assignable_boats).to include optionally_assignable_boat }
    it { expect(optionally_assignable_boats).not_to include exclusive_boat }
    it { expect(optionally_assignable_boats).to include assigned_boat }
  end

  describe ".available_between" do
    let!(:boat_booking) { create_full_booking_with_boat }
    let(:booked_boat) { boat_booking.boat }
    let!(:available_boat) { create :boat }

    context "same period as Booking" do
      let(:period) { Boat.available_between(boat_booking.start_date, boat_booking.end_date) }

      it { expect(period).not_to include booked_boat }
      it { expect(period).to include available_boat }
    end

    context "overlapping before" do
      let(:period) { Boat.available_between(boat_booking.start_date - 4.days, boat_booking.end_date - 4.days) }

      it { expect(period).not_to include booked_boat }
      it { expect(period).to include available_boat }
    end

    context "overlapping after" do
      let(:period) { Boat.available_between(boat_booking.start_date + 4.days, boat_booking.end_date + 4.days) }

      it { expect(period).not_to include booked_boat }
      it { expect(period).to include available_boat }
    end

    context "before" do
      let(:period) { Boat.available_between(boat_booking.start_date - 14.days, boat_booking.end_date - 14.days) }

      it { expect(period).to include booked_boat }
      it { expect(period).to include available_boat }
    end

    context "after" do
      let(:period) { Boat.available_between(boat_booking.start_date + 14.days, boat_booking.end_date + 14.days) }

      it { expect(period).to include booked_boat }
      it { expect(period).to include available_boat }
    end
  end

  describe "#hide!" do
    context "Given a Boat assigned to two villas" do
      let(:boat) { create :boat }

      before do
        boat.optional_villas = create_list :villa, 2
      end

      it { expect(boat.optional_villas).not_to be_empty }

      context "on hide!" do
        before do
          boat.hide!
        end

        it { expect(boat.optional_villas).to be_empty }
      end
    end
  end
end
