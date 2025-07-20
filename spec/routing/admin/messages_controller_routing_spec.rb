require "rails_helper"

RSpec.describe Admin::MessagesController do
  it { is_expected.to route(:post, "/admin/bookings/id/messages").to action: "create", booking_id: "id" }
  it { is_expected.to route(:post, "/admin/billings/id/messages").to action: "create", billing_id: "id" }
end
