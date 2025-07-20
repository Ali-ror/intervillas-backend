require "rails_helper"

RSpec.describe Api::Admin::BookingsController do
  it { is_expected.to route(:get, "/api/admin/bookings").to action: "index" }
end
