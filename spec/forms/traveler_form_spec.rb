require "rails_helper"

RSpec.describe TravelerForm do
  subject(:form) { TravelerForm.new }

  %w[first_name last_name born_on].each do |col|
    it { is_expected.to validate_presence_of col }
  end
end
