require "rails_helper"

RSpec.describe Admin::CustomersController do
  it { is_expected.to route(:patch, "/admin/customers/id").to action: "update", id: "id" }
end
