require "rails_helper"

RSpec.describe Api::Admin::InquiriesController do
  it { is_expected.to route(:get, "/api/admin/inquiries").to action: "index" }
end
