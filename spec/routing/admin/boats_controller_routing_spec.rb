require "rails_helper"

RSpec.describe Admin::BoatsController do
  it { is_expected.to route(:get,    "/admin/boats/new").to     action: :new }
  it { is_expected.to route(:post,   "/admin/boats").to         action: :create }
  it { is_expected.to route(:get,    "/admin/boats/id/edit").to action: :edit,   id: "id" }
  it { is_expected.to route(:put,    "/admin/boats/id").to      action: :update, id: "id" }
  it { is_expected.to route(:get,    "/admin/boats").to         action: :index }
  it { is_expected.to route(:delete, "/admin/boats/id").to      action: :destroy, id: "id" }
end
