require "rails_helper"

RSpec.describe Clearing::VillaParams do
  describe ".from_villa_inquiry" do
    subject(:villa_params) { described_class.from_villa_inquiry(villa_inquiry) }

    let(:villa_inquiry) { build :villa_inquiry }

    its(:villa) { is_expected.to eq villa_inquiry.villa }
    its(:start_date) { is_expected.to eq villa_inquiry.start_date }
    its(:end_date) { is_expected.to eq villa_inquiry.end_date }

    # Baut 2 erwachsene Traveler
    it { expect(villa_params.travelers.count).to eq 2 }

    # Die villa_inquiry Factory baut before(:create) Traveler-Instanzen, diese
    # werden übernommen
    context "persisted villa_inquiry" do
      let(:villa_inquiry) { create :villa_inquiry }

      its(:travelers) { is_expected.to eq villa_inquiry.travelers }
    end
  end

  describe "factory" do
    subject(:villa_params) { build :villa_params }

    its(:travelers) { is_expected.to be_present }

    it { is_expected.to be_valid }
  end
end
