require "rails_helper"

RSpec.describe "admin/accupancies routing" do
  %w[villas boats].each do |type|
    it "routes :get /admin/#{type}/occupancies to admin/occupancies#index" do
      expect(get: "/admin/#{type}/occupancies").to route_to(
        controller: "admin/occupancies",
        action:     "index",
        type:       type,
      )
    end

    it "routes :get /admin/#{type}/id/occupancies to admin/occupancies#show" do
      expect(get: "/admin/#{type}/id/occupancies").to route_to(
        controller: "admin/occupancies",
        action:     "show",
        id:         "id",
        type:       type,
      )
    end

    it {
      is_expected.to route(:get, "/admin/#{type}/id/occupancies/calendar")
        .to(controller: "admin/occupancies", action: "calendar", id: "id", type: type)
    }
  end
end
