require "rails_helper"

RSpec.describe DiscountFinder do
  subject(:discount_finder) do
    DiscountFinder.new(villa, inquiry_start_date, Date.new(2018, 0o7, 21), inquiry_created_at)
  end

  let(:villa) { create(:villa) }
  let(:inquiry_created_at) { Time.current }
  let(:inquiry_start_date) { Date.new(2018, 0o6, 21) }

  shared_examples("no christmas_nights") do
    it { expect(discount_finder.christmas_days.number_of_applicable_time_units(:nights)).to eq 0 }
  end

  shared_examples("no easter_nights") do
    it { expect(discount_finder.easter_days.number_of_applicable_time_units(:nights)).to eq 0 }
  end

  describe "#christmas_nights" do
    context "without ChristmasDiscount" do
      include_examples("no christmas_nights")
    end

    context "with ChristmasDiscount" do
      before do
        create(:holiday_discount, :christmas, villa: villa)
      end

      it { expect(villa.holiday_discounts).to be_present }

      context "not in Range" do
        include_examples("no christmas_nights")
      end

      context "new Discount, but old Booking in Range" do
        let(:inquiry_created_at) { "2017-06-05 04:03:02+01:00".to_datetime }
        let(:inquiry_start_date) { Date.new(2017, 12, 24) }

        include_examples("no christmas_nights")
      end

      context "Buchung teilweise in Range" do
        let(:inquiry_start_date) { Date.new(2017, 12, 24) }

        it { expect(discount_finder.christmas_days.number_of_applicable_time_units(:nights)).to eq 16 }
      end

      context "Buchung komplett in Range" do
        subject(:discount_finder) do
          DiscountFinder.new(villa, Date.new(2017, 12, 24), Date.new(2017, 12, 30), inquiry_created_at)
        end

        context "in Range" do
          it { expect(discount_finder.christmas_days.number_of_applicable_time_units(:nights)).to eq 6 }
          it { expect(discount_finder.nights).to eq 6 }
        end
      end

      context "6 Tage mit Jahreswechsel" do
        subject(:discount_finder) do
          DiscountFinder.new(villa, Date.new(2017, 12, 27), Date.new(2018, 1, 2), inquiry_created_at)
        end

        context "in Range" do
          it { expect(discount_finder.christmas_days.number_of_applicable_time_units(:nights)).to eq 6 }
        end
      end
    end
  end

  describe "#easter_nights" do
    context "without EasterDiscount" do
      include_examples("no easter_nights")
    end

    context "with EasterDiscount" do
      let(:days_before) { 3 }
      let(:days_after)  { 14 }

      before do
        create :holiday_discount, :easter,
          villa:       villa,
          days_before: days_before,
          days_after:  days_after
      end

      it { expect(villa.holiday_discounts).to be_present }

      context "not in Range" do
        include_examples("no easter_nights")
      end

      context "matching single day (0 nights)" do
        let(:inquiry_start_date) { Date.easter(2018) + days_after.days }

        include_examples("no easter_nights")
        it { expect(discount_finder.discounts.find { |d| d.subject == "easter" }).not_to be }
      end

      context "new Discount, but old Booking" do
        let(:inquiry_created_at) { 1.year.ago }
        let(:inquiry_start_date) { Date.new(2017, 12, 24) }

        include_examples("no easter_nights")
      end

      context "in Range" do
        let(:days_total)          { days_before + days_after }
        let(:inquiry_start_date)  { Date.easter(2018) - (days_before + 2).days }

        it { expect(discount_finder.easter_days.number_of_applicable_time_units(:nights)).to eq days_total }
      end
    end
  end

  describe "Buchung über Weihnachten und Ostern" do
    subject(:discount_finder) do
      DiscountFinder.new(villa, Date.new(2020, 11, 5), Date.new(2021, 5, 5), inquiry_created_at)
    end

    before do
      create :holiday_discount, :christmas, villa: villa
      create :holiday_discount, :easter, villa: villa
    end

    it { expect(discount_finder.easter_days).to be_present }
    it { expect(discount_finder.christmas_days).to be_present }
  end

  context "without Special" do
    describe "#special" do
      it { expect(discount_finder.special).to be_blank }
    end
  end

  context "with Special" do
    before do
      create :special, villas: [villa], start_date: inquiry_start_date, end_date: inquiry_start_date + 14.days
    end

    describe "#special" do
      it { expect(discount_finder.special).to be_present }
    end

    describe "#special_nights" do
      it { expect(discount_finder.special_days.number_of_applicable_time_units(:nights)).to eq 14 }
    end
  end

  context "without HighSeason" do
    describe "#high_season" do
      it { expect(discount_finder.high_season).to be_blank }
    end
  end

  context "with HighSeason" do
    before do
      create :high_season, villas: [villa], starts_on: inquiry_start_date
    end

    it { expect(villa.high_seasons).to be_present }

    describe "#high_season" do
      it { expect(discount_finder.high_season).to be_present }
    end

    describe "#high_season_nights" do
      it { expect(discount_finder.high_season_days.number_of_applicable_time_units(:nights)).to eq 30 }
    end

    context "with old Inquiry" do
      let(:inquiry_created_at) { 1.month.ago }

      describe "#high_season" do
        it { expect(discount_finder.high_season).to be_blank }
      end
    end
  end
end
