require "rails_helper"

RSpec.describe Admin::VillasController do
  it { is_expected.to route(:get,  "/admin/villas").to         action: "index" }
  it { is_expected.to route(:get,  "/admin/villas/new").to     action: "new" }
  it { is_expected.to route(:post, "/admin/villas").to         action: "create" }
  it { is_expected.to route(:get,  "/admin/villas/id/edit").to action: "edit",   id: "id" }
  it { is_expected.to route(:put,  "/admin/villas/id").to      action: "update", id: "id" }
end
