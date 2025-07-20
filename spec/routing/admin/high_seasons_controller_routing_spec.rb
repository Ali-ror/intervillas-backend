require "rails_helper"

RSpec.describe Admin::HighSeasonsController do
  it { is_expected.to route(:get,    "/admin/high_seasons").to         action: "index" }
  it { is_expected.to route(:get,    "/admin/high_seasons/new").to     action: "new" }
  it { is_expected.to route(:post,   "/admin/high_seasons").to         action: "create" }
  it { is_expected.to route(:get,    "/admin/high_seasons/id/edit").to action: "edit", id: "id" }
  it { is_expected.to route(:patch,  "/admin/high_seasons/id").to      action: "update", id: "id" }
  it { is_expected.to route(:delete, "/admin/high_seasons/id").to      action: "destroy", id: "id" }
end
