require "rails_helper"

RSpec.describe ChargesForm do
  it { is_expected.to validate_presence_of :amount }
  it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }

  it { is_expected.to validate_presence_of :value }
  it { is_expected.to validate_numericality_of :value }

  it { is_expected.to validate_presence_of :text }
  it { is_expected.not_to allow_value("").for :text }

  context "destroy" do
    subject { ChargesForm.new _destroy: "1" }

    it { is_expected.to be_marked_for_destruction }
    it { is_expected.to be_valid }
  end
end
