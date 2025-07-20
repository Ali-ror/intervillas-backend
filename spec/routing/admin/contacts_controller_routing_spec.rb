require "rails_helper"

RSpec.describe Admin::ContactsController do
  it { is_expected.to route(:get,   "/admin/contacts/id/edit").to action: "edit", id: "id" }
  it { is_expected.to route(:put,   "/admin/contacts/id").to      action: "update", id: "id" }
  it { is_expected.to route(:patch, "/admin/contacts/id").to      action: "update", id: "id" }
  it { is_expected.to route(:get,   "/admin/contacts/new").to     action: "new" }
  it { is_expected.to route(:post,  "/admin/contacts").to         action: "create" }
end
