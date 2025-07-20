require "rails_helper"

RSpec.describe Inquiry do
  it { is_expected.to have_many :discounts }
end
