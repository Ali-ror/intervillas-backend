require "rails_helper"

RSpec.describe Admin::InquiriesController do
  it { is_expected.to route(:get,     "/admin/inquiries").to             action: :index }
  it { is_expected.to route(:get,     "/admin/inquiries/id/edit").to     action: :edit, id: "id" }
  it { is_expected.to route(:get,     "/admin/inquiries/id").to          action: :show, id: "id" }
  it { is_expected.to route(:get,     "/admin/inquiries/new").to         action: :new }
  it { is_expected.to route(:delete,  "/admin/inquiries/id").to          action: :destroy, id: "id" }
  it { is_expected.to route(:post,    "/admin/inquiries/id/mail").to     action: :mail, id: "id" }
  it { is_expected.to route(:get,     "/admin/inquiries/search").to      action: :search_by_id }
  it { is_expected.to route(:get,     "/admin/inquiries/search_name").to action: :search_name }
end
