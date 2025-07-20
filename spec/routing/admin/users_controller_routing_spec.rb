require "rails_helper"

RSpec.describe Admin::UsersController do
  it { is_expected.to route(:get,   "/admin/users/id/edit").to action: "edit", id: "id" }
  it { is_expected.to route(:put,   "/admin/users/id").to      action: "update", id: "id" }
  it { is_expected.to route(:patch, "/admin/users/id").to      action: "update", id: "id" }
  it { is_expected.to route(:get,   "/admin/users/new").to     action: "new" }
  it { is_expected.to route(:post,  "/admin/users").to         action: "create" }
end
