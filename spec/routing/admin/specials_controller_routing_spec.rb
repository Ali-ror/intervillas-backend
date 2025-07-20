require "rails_helper"

RSpec.describe Admin::SpecialsController do
  it { is_expected.to route(:get,    "/admin/specials").to         action: "index" }
  it { is_expected.to route(:get,    "/admin/specials/id/edit").to action: "edit", id: "id" }
  it { is_expected.to route(:put,    "/admin/specials/id").to      action: "update", id: "id" }
  it { is_expected.to route(:get,    "/admin/specials/new").to     action: "new" }
  it { is_expected.to route(:post,   "/admin/specials").to         action: "create" }
  it { is_expected.to route(:delete, "/admin/specials/id").to      action: "destroy", id: "id" }
end
