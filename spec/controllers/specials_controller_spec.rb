require "rails_helper"

RSpec.describe SpecialsController, vcr: { cassette_name: "villa/geocode" } do
  render_views

  shared_examples "with special on GET to :index" do
    let(:special) { create :special }

    before do
      special.villas << villa
      get :index
    end

    it { is_expected.to assign_to(:specials) }
    it { is_expected.to render_template(:index) }
  end

  describe "given a villa with prices" do
    let(:villa) { create :villa, :bookable, :with_image }

    it_behaves_like "with special on GET to :index"
  end
end
