require "rails_helper"

RSpec.describe Admin::PreviewsController do
  it {
    is_expected.to route(:get, "/admin/bookings/id/preview").to(
      action:        "show",
      id:            "id",
      mailer_class:  "BookingMailer",
      mailer_action: "confirmation_mail",
    )
  }
end
