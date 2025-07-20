require "rails_helper"

RSpec.describe Admin::PaymentsController do
  it { is_expected.to route(:get,    "admin/payments").to                       action: :index }
  it { is_expected.to route(:get,    "admin/payments/overdue").to               action: :overdue }
  it { is_expected.to route(:get,    "admin/payments/balance/2000").to          action: :balance, year: "2000" }
  it { is_expected.to route(:post,   "admin/inquiries/inq/payments").to         action: :create, inquiry_id: "inq" }
  it { is_expected.to route(:get,    "admin/inquiries/inq/payments/id/edit").to action: :edit, inquiry_id: "inq", id: "id" }
  it { is_expected.to route(:patch,  "admin/inquiries/inq/payments/id").to      action: :update,  inquiry_id: "inq", id: "id" }
  it { is_expected.to route(:delete, "admin/inquiries/inq/payments/id").to      action: :destroy, inquiry_id: "inq", id: "id" }
end
