require "rails_helper"

RSpec.describe Api::Admin::StatsController do
  it {
    is_expected.to route(:get, "/api/admin/stats/villa_id/2019")
      .to(action: "show", villa_id: "villa_id", year: "2019")
  }

  describe "actions" do
    include_context "as_admin"

    describe "#show" do
      let(:villa) { create :villa }

      it {
        get :show, params: { villa_id: villa.to_param, year: 2019 }, format: :json

        is_expected.to respond_with :success
      }
    end
  end
end
