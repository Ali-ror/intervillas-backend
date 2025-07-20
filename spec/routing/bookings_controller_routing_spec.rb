require "rails_helper"

RSpec.describe BookingsController do
  it { is_expected.to route(:get, "/villas/villa_id/bookings/token").to action: "redirect_new", villa_id: "villa_id", token: "token" }

  # XXX: dieser spec sollte eigentlich identisch zu dem nachfolgendem sein, ist er aber nicht
  # it { is_expected.to route(:get, "/villas/villa_id/bookings/token/edit").to action: "redirect_new", villa_id: "villa_id", token: "token" }
  it {
    expect(get: "/villas/villa_id/bookings/token/edit").to route_to \
      controller: "bookings",
      action:     "redirect_new",
      villa_id:   "villa_id",
      token:      "token"
  }

  it { is_expected.to route(:post, "/inquiries/token/book").to action: "create", token: "token" }
  it { is_expected.to route(:get,  "/inquiries/token/book").to action: "new",    token: "token" }
end
