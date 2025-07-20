require "rails_helper"

RSpec.describe VillaInquiry do
  it { is_expected.to have_many :discounts }

  describe "#add_discounts" do
    subject!(:villa_inquiry) { create :villa_inquiry, villa: villa }

    let(:villa) { create :villa, :bookable }

    context "without special" do
      it { expect(villa_inquiry.discount_for(:special)).not_to be_present }
    end

    context "with special" do
      subject!(:villa_inquiry) { create :villa_inquiry, villa: villa, start_date: special.start_date }

      let!(:special) { create :special, percent: 20, villa_ids: [villa.id] }

      it { expect(villa_inquiry.discount_for(:special)).to be_present }
      it { expect(villa_inquiry.discount_for(:special).value).to eq(-20) }
    end
  end

  describe "#reset_discount before_save" do
    subject(:villa_inquiry) { create_villa_inquiry villa: villa, start_date: special.start_date }

    let(:villa) { create :villa, :bookable }
    let!(:villa2) { create :villa, :bookable }
    let!(:special) { create :special, percent: 20, villa_ids: [villa.id] }

    let!(:special_discount) { villa_inquiry.discount_for(:special) }

    before do
      expect(special_discount).not_to be_nil
      villa_inquiry.villa = villa2
      villa_inquiry.save
    end

    it { expect(villa_inquiry.discount_for(:special)).to be_nil }
  end
end
