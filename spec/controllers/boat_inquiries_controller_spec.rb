require "rails_helper"

RSpec.describe BoatInquiriesController do
  render_views
  let(:villa) { create :villa, :with_optional_boat, :bookable }

  let(:inquiry) { create_villa_inquiry(villa: villa).inquiry }

  let(:boat) { create :boat, :with_prices }

  describe "#edit" do
    before do
      get :edit, params: { token: inquiry.token }
    end

    it { is_expected.to respond_with :success }
  end

  describe "#update" do
    let(:boat) { villa.optional_boats.first }

    let(:boat_inquiry_params) {
      {
        boat_id:    boat.id,
        start_date: inquiry.start_date + 1.day,
        end_date:   inquiry.end_date - 1.day,
      }
    }

    context "valid" do
      before do
        patch :update, params: { token: inquiry.token, boat_inquiry: boat_inquiry_params }
      end

      it { is_expected.to respond_with :created }
      it { expect(response.headers["Location"]).to eq new_customer_path(token: inquiry.token) }
    end

    context "invalid" do
      before do
        boat_inquiry = boat_inquiry_params.merge(end_date: Date.current + 1.day)

        patch :update, params: { token: inquiry.token, boat_inquiry: boat_inquiry }
      end

      it { is_expected.to respond_with :unprocessable_entity }
      it { expect(JSON.parse(response.body)["date_range"]).to include("das Boot muss mindestens 3 Tage gebucht werden") }
    end
  end
end
