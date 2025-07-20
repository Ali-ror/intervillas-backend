require "rails_helper"

RSpec.describe MapsController do
  it { is_expected.to route(:get, "/karte").to action: "show" }
end
