require "rails_helper"

RSpec.describe Bsp1Response do
  it { is_expected.to belong_to :inquiry }
end
