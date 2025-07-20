require "rails_helper"

RSpec.describe CustomersController do
  it { is_expected.to route(:get,  "/inquiries/token/customer").to action: "new", token: "token" }
  it { is_expected.to route(:post, "/inquiries/token/customer").to action: "create", token: "token" }
end
