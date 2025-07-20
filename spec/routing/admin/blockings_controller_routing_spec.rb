require "rails_helper"

RSpec.describe Admin::BlockingsController do
  it { is_expected.to route(:get,    "/admin/blockings/new").to     action: "new" }
  it { is_expected.to route(:post,   "/admin/blockings").to         action: "create" }
  it { is_expected.to route(:get,    "/admin/blockings/id/edit").to action: "edit",    id: "id" }
  it { is_expected.to route(:patch,  "/admin/blockings/id").to      action: "update",  id: "id" }
  it { is_expected.to route(:delete, "/admin/blockings/id").to      action: "destroy", id: "id" }
  it { is_expected.to route(:get,    "/admin/blockings/id").to      action: "show",    id: "id" }
end
