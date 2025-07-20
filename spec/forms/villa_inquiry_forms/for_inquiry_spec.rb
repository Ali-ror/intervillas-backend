require "rails_helper"

RSpec.describe VillaInquiryForms::ForInquiry do
  subject(:form) { VillaInquiryForms::ForInquiry.from_villa_inquiry VillaInquiry.new }

  it { is_expected.to validate_presence_of :start_date }
  it { is_expected.to validate_presence_of :end_date }
  it { is_expected.to validate_presence_of :adults }

  it {
    is_expected.to validate_numericality_of(:adults)
      .only_integer
      .is_greater_than_or_equal_to(2)
  }

  [2, 34].each do |val|
    it { is_expected.to allow_value(val).for(:adults) }
  end

  [0, -2].each do |val|
    it { is_expected.not_to allow_value(val).for(:adults) }
  end

  %w[children_under_6 children_under_12].each do |col|
    it {
      is_expected.to validate_numericality_of(col)
        .only_integer
        .is_greater_than_or_equal_to(0)
    }

    [nil, "", 0, 1, 34].each do |val|
      it { is_expected.to allow_value(val).for(col) }
    end

    it { is_expected.not_to allow_value(-2).for(col) }
  end

  describe ".validates starts_in_future" do
    subject(:villa_inquiry) { VillaInquiryForms::ForInquiry.from_villa_inquiry VillaInquiry.new(start_date: start_date) }

    context "invalid" do
      let(:start_date) { Date.yesterday }

      it { expect(villa_inquiry).to have_error(:future, on: :start_date, after: I18n.l(2.days.from_now.to_date)) }
    end

    context "invalid (tomorrow)" do
      let(:start_date) { Date.tomorrow }

      it { expect(villa_inquiry).to have_error(:future, on: :start_date, after: I18n.l(2.days.from_now.to_date)) }
    end

    context "valid" do
      let(:start_date) { 2.days.from_now }

      it { expect(villa_inquiry).not_to have_error(:future, on: :start_date, after: I18n.l(2.days.from_now.to_date)) }
    end
  end

  describe ".validates ends_after_start" do
    subject(:form) { VillaInquiryForms::ForInquiry.from_villa_inquiry villa_inquiry }

    let(:villa_inquiry) { VillaInquiry.new(start_date: Date.tomorrow, end_date: end_date) }

    include_examples "validates_ends_after_start"
  end

  describe ".validates minimum_length" do
    subject(:form) { VillaInquiryForms::ForInquiry.from_villa_inquiry(villa_inquiry) }

    let(:villa_inquiry) { VillaInquiry.new(villa: villa, start_date: Date.tomorrow, end_date: end_date) }
    let(:villa)         { nil }

    shared_examples "min length validation" do |expected = nil|
      context "invalid" do
        let(:end_date)   { Date.tomorrow + 1.day }
        let(:min_length) { VillaInquiry.minimum_booking_nights(Date.tomorrow, villa: villa) }

        it { expect(min_length).to eq expected } if expected
        it { expect(form).to have_error(:min_length, on: :end_date, count: min_length) }
      end

      context "valid" do
        let(:end_date) { Date.tomorrow + VillaInquiry.minimum_booking_nights(Date.tomorrow, villa: villa) }

        it { expect(form).not_to have_error(:min_length, on: :end_date) }
      end
    end

    context "without villa", :skip_on_xmas do
      # XXX: not sure why this fails when the time on the host machine is a few days before christmas
      include_examples "min length validation"
    end

    context "with villa" do
      let(:villa)      { create :villa, minimum_booking_nights: min_nights }
      let(:min_nights) { 3 }

      context "minimum_booking_nights == 3", :skip_on_xmas do
        # XXX: not sure why this fails when the time on the host machine is a few days before christmas
        include_examples "min length validation", 3
      end

      context "minimum_booking_nights == 14" do
        let(:min_nights) { 14 }

        include_examples "min length validation", 14
      end
    end
  end

  describe ".validates already_booked" do
    subject(:form) { VillaInquiryForms::ForInquiry.from_villa_inquiry villa_inquiry }

    let(:villa_inquiry) {
      VillaInquiry.new(
        villa:      villa,
        start_date: clashing_booking.start_date,
        end_date:   clashing_booking.end_date,
      )
    }

    include_examples "validates_availability"
  end

  # Anfrage darf minimale Anzahl Nächte unterschreiten,
  # wenn durch andere Buchungen nicht mehr Nächte möglich sind.
  # -> Lücken füllen
  context "date gap" do
    include_context "gap"

    describe "validation" do
      subject(:form) { VillaInquiryForms::ForInquiry.from_villa_inquiry villa_inquiry }

      let(:villa_inquiry) { VillaInquiry.new(villa: villa, start_date: today, end_date: today + min_gap.days) }
      let(:before_range)  { [today - 10.days, today] }
      let(:after_range)   { [today + gap, today + gap + 10.days] }

      before do
        create_full_booking villa: villa, start_date: before_range[0], end_date: before_range[1]
        create_full_booking villa: villa, start_date: after_range[0],  end_date: after_range[1]
      end

      it "has a minimum gap size of 1" do
        expect(NightsCalculator::MINIMUM_BOOKING_NIGHTS).to be >= 1
      end

      context "gap of exactly MINIMUM_BOOKING_NIGHTS" do
        it { expect(form).not_to have_error(:min_length, on: :end_date) }
        it { expect(form).not_to have_error(:already_booked, on: :start_date) }
      end

      context "gap of MINIMUM_BOOKING_NIGHTS - 1" do
        let(:gap) { (min_gap - 1).days }

        it { expect(form).to have_error(:already_booked, on: :start_date) }
      end

      context "gap of MINIMUM_BOOKING_NIGHTS - 1 / booking the same" do
        let(:min_gap) { NightsCalculator::MINIMUM_BOOKING_NIGHTS - 1 }
        let(:gap) { min_gap.days }

        it { expect(form).not_to have_error(:already_booked, on: :start_date) }
        it { expect(form).not_to have_error(:min_length, on: :end_date) }
      end

      context "gap of MINIMUM_BOOKING_NIGHTS - 2 / booking - 1" do
        let(:min_gap) { NightsCalculator::MINIMUM_BOOKING_NIGHTS - 2 }
        let(:gap) { (min_gap + 1).days }

        it { expect(form).to have_error(:min_length, on: :end_date, count: 6) }
      end

      context "gap of MINIMUM_BOOKING_NIGHTS + 1" do
        let(:gap) { (min_gap + 1).days }

        it { expect(form).not_to have_error(:min_length, on: :end_date) }
        it { expect(form).not_to have_error(:already_booked, on: :start_date) }
      end
    end
  end
end
