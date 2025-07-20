require "rails_helper"

RSpec.describe Admin::ComparisonsController do
  it { is_expected.to route(:get, "/admin/stats/compare").to(action: "index") }

  context "als Admin" do
    render_views
    include_context "as_admin"

    describe "#index" do
      it {
        get :index
        is_expected.to render_template "index"
      }
    end
  end
end
