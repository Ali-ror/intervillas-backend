require "rails_helper"

RSpec.describe Api::VillasController, vcr: { cassette_name: "villa/geocode" } do
  before do
    create :category, :bedrooms
    create :category, :bathrooms
  end

  describe "on GET to :prefetch" do
    subject(:villa_object) {
      get :prefetch, params: { format: :json }
      array = JSON.parse response.body
      array.first
    }

    let(:villa) { build :villa }

    before do
      allow(villa).to receive(:attach_geocode)
      villa.domains << (Domain.find_by(default: true) || create(:domain))
      villa.save
    end

    it "renders villa object with :name and :path" do
      expect(villa_object).to have_key "name"
      expect(villa_object).to have_key "path"
    end

    it "has correct name" do
      expect(villa_object["name"]).to eq villa.name
    end

    it "has correct path" do
      expect(villa_object["path"]).to eq("/ferienhaus-cape-coral/" << villa.to_param)
    end
  end
end
