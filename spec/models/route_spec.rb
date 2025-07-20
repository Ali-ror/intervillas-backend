require "rails_helper"

RSpec.describe Route do
  describe "Villa#cache_key" do
    subject(:route) { create(:villa, updated_at: 1.hour.ago).route }

    before do
      allow(route.resource).to receive :attach_geocode
      route.resource.updated_at = 1.hour.ago
      route.resource.save
    end

    it "changes with path" do
      expect { route.path = "foo"; route.save! }.to change { route.resource.reload; route.resource.cache_key }
    end
  end
end
