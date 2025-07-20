require "rails_helper"

RSpec.describe VillaInquiriesController do
  it { is_expected.to route(:get,  "/villas/villa_id/inquiries/new").to     action: "new",    villa_id: "villa_id" }
  it { is_expected.to route(:post, "/villas/villa_id/inquiries").to         action: "create", villa_id: "villa_id" }
  it { is_expected.to route(:get,  "/villas/villa_id/inquiries/id/edit").to action: "edit",   villa_id: "villa_id", id: "id" }
end
