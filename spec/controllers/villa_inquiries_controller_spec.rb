require "rails_helper"

RSpec.describe VillaInquiriesController do
  render_views

  let(:villa) { create :villa, :displayable, :bookable }

  describe "#new" do
    let(:next_year) { Date.current.year + 1 }

    before do
      get :new, params: {
        villa_id: villa.id,
        start:    "#{next_year}-07-23",
        end:      "#{next_year}-07-30",
      }
    end

    it { is_expected.to redirect_to de_villa_path(villa, start_date: "#{next_year}-07-23", end_date: "#{next_year}-07-30") }
  end

  describe "#create" do
    before do
      post :create, params: params.merge(villa_id: villa.id)
    end

    context "invalid" do
      let(:params) { { villa_inquiry: { some: :params } } }

      it { is_expected.to respond_with :unprocessable_entity }

      it "responds with errors" do
        expect(JSON.parse(response.body)).to include(
          "adults"     => match(["muss ausgefüllt werden", "ist keine Zahl"]),
          "date_range" => match(["muss ausgefüllt werden", /^muss in der Zukunft liegen/, /die Mindestdauer der Reise beträgt \d+ Nächte/]),
        )
      end
    end

    context "valid" do
      let(:params) { { villa_inquiry: attributes_for(:villa_inquiry) } }

      it { is_expected.to respond_with :created }
      it { expect(response.headers["Location"]).to eq "/inquiries/#{Inquiry.last.token}/customer" }
    end

    context "valid with optional boat" do
      let(:villa) { create :villa, :with_optional_boat, :bookable }
      let(:params) { { villa_inquiry: attributes_for(:villa_inquiry) } }

      it { is_expected.to respond_with :created }
      it { expect(response.headers["Location"]).to eq "/inquiries/#{Inquiry.last.token}/boat" }
    end
  end

  describe "#edit" do
    let(:inquiry) { create_villa_inquiry.inquiry }
    let(:villa) { inquiry.villa }

    before do
      get :edit, params: { id: inquiry.token, villa_id: villa.id }
    end

    it "redirects to villa#show and sets params for the request form" do
      params = {
        start_date: inquiry.start_date,
        end_date:   inquiry.end_date,
        people:     {
          0 => inquiry.adults,
          1 => inquiry.children_under_12,
          2 => inquiry.children_under_6,
        },
      }

      expect(response).to redirect_to de_villa_path(villa, **params)
    end
  end
end
