require "rails_helper"

RSpec.describe MapsController, vcr: { cassette_name: "villa/geocode" } do
  describe "GET to :show" do
    before { get :show }

    it { is_expected.to render_template(:show) }
  end

  describe "POST to :api_key" do
    let(:villa) { build :villa, :bookable, :displayable, :with_geocode }

    before do
      villa.domains << (Domain.find_by(default: true) || create(:domain))
      villa.save!
    end

    context "for overview" do
      before { post :api_key, params: { format: :json } }

      it { is_expected.to respond_with_content_type("application/json") }
      it { is_expected.to respond_with(:success) }

      it "returns API key and villa teaser payload" do
        # general shape of response data:
        #   {
        #     api_key: String,    # Maps API key
        #     payload: {          # only present for overview
        #       villas: [ ... ],  # list of villa teaser data + lat/lng
        #       labels: { ... },  # labels for <TeaserVilla/> component
        #     },
        #   }
        data = JSON.parse response.body

        expect(data).to match({
          "api_key" => be_kind_of(String),
          "payload" => match({
            "villas" => contain_exactly(include(
              "id"   => villa.id,
              "name" => villa.name,
              "lat"  => villa.geocode.latitude,
              "lng"  => villa.geocode.longitude,
            )),
            "labels" => be_kind_of(Hash),
          }),
        })
      end
    end

    it "fails with unknown villa" do
      expect {
        post :api_key, params: { villa_id: villa.id + 1, format: :json }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    describe "with known villa" do
      before { post :api_key, params: { villa_id: villa.id, format: :json } }

      it { is_expected.to respond_with_content_type("application/json") }
      it { is_expected.to respond_with(:success) }

      it "returns only the API key" do
        data = JSON.parse response.body

        expect(data).to     have_key "api_key"
        expect(data).not_to have_key "payload"
      end
    end
  end
end
