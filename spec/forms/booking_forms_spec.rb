require "rails_helper"

RSpec.describe BookingForms::Customer do
  subject { described_class.from_inquiry build(:inquiry, :with_villa_inquiry) }

  it { is_expected.to validate_acceptance_of :agb }
end
