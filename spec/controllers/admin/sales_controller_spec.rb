require "rails_helper"

RSpec.describe Admin::SalesController do
  it { is_expected.to route(:get, "/admin/sales").to(action: "index") }

  include_context "as_admin" do
    describe "#index" do
      it {
        get :index

        is_expected.to respond_with :success
      }
    end
  end
end
