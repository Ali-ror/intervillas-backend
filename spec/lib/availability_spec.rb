require "rails_helper"

RSpec.describe Availability do
  # noinspection RubyArgCount
  subject { Availability.new inquiry }

  let(:start_date)  { generate :booking_dates }
  let(:end_date)    { start_date + 8.days }
  let(:villa)       { create :villa, :bookable }
  let(:inquiry)     { create :villa_inquiry, villa: villa, start_date: start_date, end_date: end_date }

  its(:inquiry_class)   { is_expected.to be VillaInquiry }
  its(:rentable_id_key) { is_expected.to eq "villa_id" }
  its(:rentable)        { is_expected.to be villa }

  it { is_expected.to be_still_available }
  its(:conflicting_bookings)  { is_expected.to be_empty }
  its(:conflicting_blockings) { is_expected.to be_empty }

  context "when booked" do
    let!(:booking) { create_full_booking villa: villa, start_date: start_date - 7.days, end_date: start_date + 3.days }

    it { is_expected.not_to be_still_available }
    its(:conflicting_bookings)  { is_expected.to eq [booking.villa_inquiry] }
    its(:conflicting_blockings) { is_expected.to be_empty }

    context "but cancelled" do
      before { booking.inquiry.cancel! }

      it { is_expected.to be_still_available }
      its(:conflicting_bookings)  { is_expected.to be_empty }
      its(:conflicting_blockings) { is_expected.to be_empty }
    end
  end

  context "when blocked" do
    let!(:blocking) { create :blocking, villa: villa, start_date: end_date - 3.days, end_date: end_date + 6.weeks }

    it { is_expected.not_to be_still_available }
    its(:conflicting_bookings)  { is_expected.to be_empty }
    its(:conflicting_blockings) { is_expected.to eq [blocking] }
  end

  context "when reserved" do
    let!(:reservation) {
      create_reservation(villa:      villa,
                         start_date: end_date - 3.days,
                         end_date:   end_date + 6.weeks)
    }

    its(:conflicting_reservations) { is_expected.to eq [reservation] }

    context "more than 30 Minuten ago" do
      before do
        reservation.update! created_at: 31.minutes.ago
      end

      its(:conflicting_reservations) { is_expected.to be_empty }
    end
  end
end
