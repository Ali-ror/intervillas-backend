require "rails_helper"

RSpec.describe BoatInquiryForms::ForInquiry do
  subject(:form) { BoatInquiryForms::ForInquiry.from_boat_inquiry boat_inquiry }

  let(:boat) { create :boat }
  let(:boat_inquiry) { BoatInquiry.new(boat: boat) }

  # it { is_expected.not_to validate_presence_of :start_date }
  # it { is_expected.not_to validate_presence_of :end_date }

  context "with boat" do
    it { is_expected.to validate_presence_of :start_date }
    it { is_expected.to validate_presence_of :end_date }

    describe ".validates starts_in_future" do
      context "invalid" do
        before do
          form.start_date = Date.yesterday
        end

        it { expect(form).to have_error(:future, on: :start_date, after: I18n.l(2.days.from_now.to_date)) }
      end

      context "valid" do
        before do
          form.start_date = 2.days.from_now
        end

        it { expect(form).not_to have_error(:future, on: :start_date) }
      end
    end

    describe ".validates ends_after_start" do
      before do
        form.start_date = Date.tomorrow
      end

      context "invalid" do
        before do
          form.end_date = Date.yesterday
        end

        it { expect(form).to have_error(:after_start, on: :end_date) }
      end

      context "valid" do
        before do
          form.end_date = Date.tomorrow + 1.day
        end

        it { expect(form).not_to have_error(:after_start, on: :end_date) }
      end
    end

    describe "validates :min_boat_length" do
      before do
        form.start_date = Date.current
      end

      context "min_length = 3" do
        let(:boat) { create :boat, minimum_days: 3 }

        context "book 2 days" do
          before do
            form.end_date = Date.current + 1.day
          end

          it { expect(form).to have_error :min_boat_length, on: :end_date, count: 3 }
        end

        context "book 3 days" do
          before do
            form.end_date = Date.current + 2.days
          end

          it { expect(form).not_to have_error :min_boat_length, on: :end_date, count: 3 }
        end
      end

      context "min_length = 5" do
        let(:boat) { create :boat, minimum_days: 5 }

        context "book 2 days" do
          before do
            form.end_date = Date.current + 1.day
          end

          it { expect(form).to have_error :min_boat_length, on: :end_date, count: 5 }
        end

        context "book 5 days" do
          before do
            form.end_date = Date.current + 4.days
          end

          it { expect(form).not_to have_error :min_boat_length, on: :end_date, count: 5 }
        end
      end
    end

    describe "validates :availability" do
      let!(:boat_booking) { create_full_booking_with_boat }
      let(:boat) { boat_booking.boat }

      context "overlapping" do
        before do
          form.start_date = boat_booking.start_date
          form.end_date   = boat_booking.end_date + 5.days
        end

        it { expect(form).to have_error(:already_booked, on: :start_date) }
        it { expect(form).to have_error(:already_booked, on: :end_date) }
      end

      context "not overlapping" do
        before do
          form.start_date = boat_booking.start_date + 1.month
          form.end_date   = boat_booking.end_date + 2.months
        end

        it { expect(form).not_to have_error(:already_booked, on: :start_date) }
        it { expect(form).not_to have_error(:already_booked, on: :end_date) }
      end
    end
  end

  describe "with villa_inquiry with optional boat" do
    subject(:boat_inquiry_form) { BoatInquiryForms::ForInquiry.from_boat_inquiry(boat_inquiry) }

    let(:villa) { create :villa, :with_optional_boat, :bookable }
    let(:villa_inquiry) { create_villa_inquiry(villa: villa) }
    let(:inquiry) { villa_inquiry.inquiry }
    let(:boat_inquiry) { inquiry.prepare_boat_inquiry }

    before do
      boat_inquiry_form.villa_inquiry = villa_inquiry
    end

    context "different boat booking dates" do
      let(:offset) { 0 }

      before do
        boat_inquiry_form.start_date = villa_inquiry.start_date + offset.days
        boat_inquiry_form.end_date   = villa_inquiry.end_date - offset.days
      end

      describe "not possible to overlap boat- with booking start/end date" do
        it { expect(boat_inquiry_form).to have_error :overlaps_with_start_date, on: :start_date }
        it { expect(boat_inquiry_form).to have_error :overlaps_with_end_date, on: :end_date }
      end

      describe "capping off arrival and departure date" do
        let(:offset) { 1 }

        it { is_expected.to be_valid }
      end

      describe "setting boat time too short" do
        before do
          boat_inquiry_form.start_date = villa_inquiry.start_date + 1.day
          boat_inquiry_form.end_date   = villa_inquiry.start_date + 2.days
          boat_inquiry_form.valid?
        end

        it { expect(boat_inquiry_form).to have_error :min_boat_length, on: :end_date, count: 3 }
      end
    end
  end
end
