require "rails_helper"

RSpec.describe SpecialsController do
  it { is_expected.to route(:get, "/specials").to action: "index" }
end
