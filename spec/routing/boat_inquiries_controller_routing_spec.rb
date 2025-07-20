require "rails_helper"

RSpec.describe BoatInquiriesController do
  it { is_expected.to route(:get,   "/inquiries/tok/boat").to action: "edit",   token: "tok" }
  it { is_expected.to route(:patch, "/inquiries/tok/boat").to action: "update", token: "tok" }
end
