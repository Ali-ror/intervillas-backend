require "rails_helper"

RSpec.describe Admin::BookingsController do
  it { is_expected.to route(:get,  "/admin/bookings").to         action: "index" }
  it { is_expected.to route(:get,  "/admin/bookings/id").to      action: "show", id: "id" }
  it { is_expected.to route(:get,  "/admin/bookings/id/edit").to action: "edit", id: "id" }
  it { is_expected.to route(:post, "/admin/bookings/id/mail").to action: "mail", id: "id" }
end
