require "rails_helper"

RSpec.describe "Villas::Media" do
  describe "#main_image" do
    subject(:main_image) { villa.main_image }

    let(:images) { create_list :image, 3, :active, parent: villa }

    let!(:villa) { create :villa }

    before do
      images
    end

    it "got set" do
      expect(villa.images).to be_present
    end

    it "is present" do
      expect(main_image).to be_present
    end

    it "is teh first image" do
      expect(main_image).to eq images.first
    end

    context "first is inactive" do
      before do
        villa.images.first.update! active: false
      end

      it "is teh second image" do
        expect(main_image).to eq images.second
      end
    end

    it "can be included" do
      expect(Villa.includes(:main_image).first.main_image).to be_present
    end
  end
end
