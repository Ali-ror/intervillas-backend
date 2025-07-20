require "rails_helper"

RSpec.describe Clearing::Villa::Builder do
  shared_context "#build" do
    before { builder.build }

    its(:clearing_items) { is_expected.to be_present }
    its(:clearing_items) { is_expected.to include have_attributes category: "deposit" }
    its(:clearing_items) { is_expected.to include have_attributes category: "cleaning" }
  end

  # Die neue Preisstruktur basiert auf einem Grundpreis für 2 Personen
  # und gleichen Aufschlägen für jede weitere Person.
  context "BaseRate" do
    subject(:builder) { described_class.new(villa_params) }

    let(:villa_params) { build :villa_params }

    its(:legacy_price_structure?) { is_expected.to be_falsey }

    describe "#build" do
      include_context "#build"

      its(:clearing_items) { is_expected.to include have_attributes category: "base_rate", amount: 1, price: 160 }
    end
  end

  # Das ursprüngliche Preismodell ermöglichte das Eintragen von Übernachtungspreisen pro
  # Person für jede mögliche Belegung. 80 bei 2er Belegung, 70 bei 3er usw.
  #
  # Wird jetzt noch verwendet für Bestandsbuchungen verwendet, wenn die Buchung ein ClearingItem
  #
  context "per Occupancy price" do
    subject(:builder) { described_class.new(villa_params, inquiry: villa_inquiry.inquiry) }

    let(:villa_inquiry) { create :villa_inquiry, :legacy_prices }
    let(:villa_params) { Clearing::VillaParams.from_villa_inquiry(villa_inquiry) }

    # Es muss bereits ein ClearingItem über :adults existieren
    it { expect(villa_inquiry.clearing_items).to include have_attributes category: "adults" }

    its(:legacy_price_structure?) { is_expected.to be_truthy }

    describe "#build" do
      include_context "#build"

      its(:clearing_items) { is_expected.to include have_attributes category: "adults" }
    end
  end

  context "existing Inquiry with ClearingItem of :base_rate" do
    subject(:builder) { described_class.new(villa_params, inquiry: villa_inquiry.inquiry) }

    let(:villa_inquiry) { create :villa_inquiry }
    let(:villa_params) { Clearing::VillaParams.from_villa_inquiry(villa_inquiry.inquiry) }

    # Es muss bereits ein ClearingItem über :base_rate existieren
    it { expect(villa_inquiry.clearing_items).to include have_attributes category: "base_rate" }

    its(:legacy_price_structure?) { is_expected.to be_falsey }

    describe "#build" do
      include_context "#build"

      its(:clearing_items) { is_expected.to include have_attributes category: "base_rate", amount: 1, price: 160 }
    end
  end

  describe "#group_travelers" do
    skip "TODO"
  end
end
