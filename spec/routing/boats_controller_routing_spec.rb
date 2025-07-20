require "rails_helper"

RSpec.describe BoatsController do
  it { is_expected.to route(:get, "/boats/id").to action: "show", id: "id" }
end
