require "rails_helper"

RSpec.describe FallbackController, vcr: { cassette_name: "villa/geocode" } do
  describe "Routing" do
    let(:villa) { create(:villa) }

    before do
      create :route, name: "test_route", path: "test-route", controller: "fallback", action: "test"
      villa.route.update(
        name:       "test_route_1",
        path:       "test-route-1",
        controller: "fallback",
        action:     "test",
      )
      Intervillas::Application.reload_routes!
    end

    it { is_expected.to route(:get, "/test-route").to(controller: "fallback", action: "test", id: nil) }
    it { is_expected.to route(:get, "/test-route-1").to(controller: "fallback", action: "test", id: villa.to_param) }
  end
end
