require "rails_helper"

RSpec.describe Admin::HighSeasonsController do
  include_context "as_admin"

  matcher :expose do |expected|
    match do |controller|
      controller.view_context.respond_to?(expected) &&
        values_match?(chained_matcher, exposed_value)
    end

    chain :and_expect_it_to, :chained_matcher

    def exposed_value
      @exposed_value ||= controller.view_context.send(expected)
    end
  end

  describe "#new" do
    before do
      get :new
    end

    it { is_expected.to respond_with :success }

    describe "#high_season" do
      it { expect(controller).to expose(:high_season).and_expect_it_to be_new_record }
    end
  end

  describe "#create" do
    before do
      high_season = double("HighSeason", :"attributes=" => nil, save: true)
      controller.instance_variable_set(:@high_season, high_season)
      post :create, params: { high_season: { valid: :params } }
    end

    it { is_expected.to respond_with :redirect }
  end

  context "mit high_season" do
    let!(:high_season) { create :high_season }

    describe "#index" do
      before do
        get :index
      end

      it { is_expected.to respond_with :success }

      describe "#high_seasons" do
        it { expect(controller).to expose(:high_seasons).and_expect_it_to include high_season }
      end
    end

    describe "#edit" do
      before do
        get :edit, params: { id: high_season.to_param }
      end

      it { is_expected.to respond_with :success }

      describe "#high_season" do
        it { expect(controller).to expose(:high_season).and_expect_it_to be_persisted.and(eq high_season) }
      end
    end

    describe "#update" do
      before do
        expect(high_season).to receive(:save).and_return(true)
        controller.instance_variable_set(:@high_season, high_season)
        patch :update, params: { id: high_season.to_param, high_season: { valid: :params } }
      end

      it { is_expected.to respond_with :redirect }
    end

    describe "#destroy" do
      before do
        expect(high_season).to receive(:destroy).and_return(true)
        controller.instance_variable_set(:@high_season, high_season)
        delete :destroy, params: { id: high_season.to_param }
      end

      it { is_expected.to respond_with :redirect }
    end
  end
end
