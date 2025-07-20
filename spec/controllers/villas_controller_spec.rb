RSpec.describe VillasController, vcr: { cassette_name: "villa/geocode" } do
  # before { sign_in_admin }

  before do
    create :category, :bedrooms
    create :category, :bathrooms
  end

  describe "on GET to :index" do
    before do
      get :index, params: { locale: "de" }
    end

    it { is_expected.to render_template(:index) }
    it { is_expected.to respond_with(:success) }
  end

  describe "on GET to :show" do
    render_views
    let(:villa_active) { true }
    let(:villa) { create :villa, :displayable, :bookable, active: villa_active }

    before do
      get :show, params: { id: villa.to_param, locale: "de" }
    end

    it { is_expected.to render_template(:show) }
    it { is_expected.to render_template(partial: "_show") }
    it { is_expected.to respond_with(:success) }

    context "with inactive villa" do
      let(:villa_active) { false }

      it { is_expected.to render_template(:show) }
      it { is_expected.to render_template(partial: "_gone") }
      it { is_expected.to respond_with(:gone) }
    end
  end
end
