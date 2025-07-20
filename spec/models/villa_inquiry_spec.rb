require "rails_helper"

RSpec.describe VillaInquiry do
  it { is_expected.to belong_to :villa }
  it { is_expected.to belong_to :inquiry }

  context "eine Anfrage" do
    subject(:villa_inquiry) { create_villa_inquiry }

    let(:travelers) { villa_inquiry.inquiry.travelers }

    it "erstellt automatisch Reisende" do
      expect(travelers.count).to eq 2
    end

    it "mit nested attributes" do
      inquiry   = villa_inquiry.inquiry
      new_start = villa_inquiry.start_date - 1.day
      new_end   = villa_inquiry.end_date + 1.day

      # Zwei Teilnehmer kommen früher und gehen später, ein weiterer bleibt
      # über den ursprünglichen Zeitraum
      inquiry.update(
        travelers_attributes: travelers.map { |t|
          { id: t.id, start_date: new_start, end_date: new_end }
        } + [{ price_category: "adults", start_date: villa_inquiry.start_date, end_date: villa_inquiry.end_date }],
      )

      villa_inquiry.reload
      expect(villa_inquiry.start_date).to eq new_start
      expect(villa_inquiry.end_date).to eq new_end
    end
  end

  describe "factory" do
    subject(:villa_inquiry) { create :villa_inquiry }

    it "uses current_prices" do
      expect(villa_inquiry.clearing_items).to include have_attributes(category: "base_rate")
    end

    describe ":legacy_prices" do
      subject(:villa_inquiry) { create :villa_inquiry, :legacy_prices }

      it "uses legacy_prices" do
        expect(villa_inquiry.clearing_items).to include have_attributes(category: "adults")
      end
    end

    # Reisende direkt an :villa_inquiry übergeben
    describe "#travelers" do
      subject(:villa_inquiry) {
        create :villa_inquiry,
          travelers: travelers
      }

      let(:travelers) {
        [
          *build_list(:traveler, 2,
            start_date: start_date,
            end_date:   Date.new(2020, 1, 8)),
          build(:traveler,
            start_date: start_date,
            end_date:   Date.new(2020, 1, 5)),
        ]
      }

      let(:start_date) { Date.new(2020, 1, 1) }

      shared_examples "contains 3 Travelers" do
        it "contains 3 Travelers" do
          expect(villa_inquiry.travelers.count).to eq 3
        end
      end

      include_examples "contains 3 Travelers"

      context "with :legacy_prices" do
        subject(:villa_inquiry) {
          create :villa_inquiry,
            :legacy_prices,
            travelers: travelers
        }

        include_examples "contains 3 Travelers"
      end

      context "children_under_12:" do
        subject(:villa_inquiry) {
          create :villa_inquiry,
            children_under_12: 2
        }

        its(:travelers) { is_expected.to include(have_attributes(price_category: "children_under_12")) }
        it { expect(villa_inquiry.travelers.where(price_category: "children_under_12").count).to eq 2 }
      end
    end

    matcher :overlap do |high_season|
      match do |inquiry|
        high_season.overlaps? inquiry.start_date..inquiry.end_date
      end
    end

    describe ":high_season" do
      subject(:villa_inquiry) { create :villa_inquiry, :high_season }

      it "overlaps high_season" do
        expect(villa_inquiry).to overlap(HighSeason.last)
      end
    end

    describe ":with_boat" do
      subject(:villa_inquiry) { create :villa_inquiry, :villa_with_optional_boat }

      it { expect(villa_inquiry.villa.optional_boats).to be_present }
    end
  end
end
