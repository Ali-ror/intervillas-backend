require "rails_helper"

RSpec.describe Api::Admin::SalesController do
  it { is_expected.to route(:get, "/api/admin/sales").to(action: "index") }

  include_context "as_admin" do
    describe "#index" do
      it {
        get :index, params: { date: "2019-7-18" }, format: "json"

        is_expected.to respond_with :success
      }
    end
  end
end
