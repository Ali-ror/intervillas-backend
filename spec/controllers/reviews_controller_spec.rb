require "rails_helper"

RSpec.describe ReviewsController do
  context "nested" do
    let(:villa) { create :villa, :displayable, :bookable }

    describe "#index" do
      before do
        get :index, params: { villa_id: villa.id, locale: "de" }
      end

      it { is_expected.to respond_with :success }

      context "!active -> :gone" do
        let(:villa) { create :villa, :displayable, :bookable, active: false }

        it { is_expected.to respond_with :gone }
      end
    end

    describe "#show" do
      let(:booking) { create_full_booking villa: villa }
      let(:review) { create :review, :published, inquiry: booking.inquiry }

      before do
        get :show, params: { villa_id: villa.id, id: review.id }
      end

      it { is_expected.to redirect_to villa_reviews_path(villa, anchor: "review_#{review.id}") }
    end
  end

  context "flat" do
    describe "#index" do
      before do
        get :index, params: { locale: "de" }
      end

      it { is_expected.to respond_with :success }
    end
  end
end
