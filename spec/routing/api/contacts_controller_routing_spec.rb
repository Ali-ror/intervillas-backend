require "rails_helper"

RSpec.describe Api::ContactsController do
  it { is_expected.to route(:post, "/api/contacts").to action: "create" }
end
