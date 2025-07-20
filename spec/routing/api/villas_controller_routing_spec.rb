require "rails_helper"

RSpec.describe Api::VillasController do
  it { is_expected.to route(:get, "/api/villas/id").to action: "show", id: "id" }
  it { is_expected.to route(:get, "/api/villas/facets").to action: "facets" }
  it { is_expected.to route(:get, "/api/villas/prefetch").to action: "prefetch" }
end
