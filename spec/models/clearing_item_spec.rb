require "rails_helper"

RSpec.describe ClearingItem do
  it { is_expected.to belong_to :inquiry }
  it { is_expected.to belong_to(:booking).optional }
  it { is_expected.to belong_to(:villa_inquiry).optional }
  it { is_expected.to belong_to(:villa).optional }
  it { is_expected.to belong_to(:boat).optional }

  context "Hausmiete" do
    subject(:clearing_item) do
      create :clearing_item,
        category:   "adults",
        villa:      villa,
        price:      10,
        start_date: Date.new(2019, 1, 1),
        end_date:   Date.new(2019, 1, 10)
    end

    let(:villa) { create(:villa) }

    it { expect(clearing_item.time_units).to eq 9 }
    it { expect(clearing_item.human_time_units).to eq "9 Nächte" }
    it { expect(clearing_item.total).to eq 90 }
  end

  context "Bootmiete" do
    subject(:clearing_item) do
      create :clearing_item,
        category:   "price",
        boat:       boat,
        price:      10,
        start_date: Date.new(2019, 1, 1),
        end_date:   Date.new(2019, 1, 10)
    end

    let(:boat) { create(:boat) }

    it { expect(clearing_item.time_units).to eq 10 }
    it { expect(clearing_item.human_time_units).to eq "10 Tage" }
    it { expect(clearing_item.total).to eq 100 }
  end

  shared_context "en" do
    before do
      I18n.locale = :en
    end

    after do
      I18n.locale = I18n.default_locale
    end
  end

  describe "#human_time_units" do
    subject(:clearing_item) { build(:clearing_item, time_units: length, villa_id: villa_id, boat_id: boat_id) }

    context "villa" do
      # Da nur :build benutzt wird, reicht es eine villa_id anzugeben. Ob diese existiert ist für diesen Test egal
      let(:villa_id) { 1 }
      let(:boat_id) { nil }

      context "one" do
        let(:length) { 1 }

        its(:human_time_units) { is_expected.to eq "1 Nacht" }

        it_behaves_like "en" do
          its(:human_time_units) { is_expected.to eq "1 night" }
        end
      end

      context "many" do
        let(:length) { 7 }

        its(:human_time_units) { is_expected.to eq "7 Nächte" }

        it_behaves_like "en" do
          its(:human_time_units) { is_expected.to eq "7 nights" }
        end
      end
    end

    context "boat" do
      # Da nur :build benutzt wird, reicht es eine villa_id anzugeben. Ob diese existiert ist für diesen Test egal
      let(:villa_id) { nil }
      let(:boat_id) { 1 }

      context "one" do
        let(:length) { 0 }

        its(:human_time_units) { is_expected.to eq "1 Tag" }

        it_behaves_like "en" do
          its(:human_time_units) { is_expected.to eq "1 day" }
        end
      end

      context "many" do
        let(:length) { 6 }

        its(:human_time_units) { is_expected.to eq "7 Tage" }

        it_behaves_like "en" do
          its(:human_time_units) { is_expected.to eq "7 days" }
        end
      end
    end
  end
end
