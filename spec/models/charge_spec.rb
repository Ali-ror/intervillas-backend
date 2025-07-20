require "rails_helper"

RSpec.describe Charge, vcr: { cassette_name: "booking/geocode" } do
  subject { create :charge }

  context "validations" do
    %w[villa_billing_id boat_billing_id text amount value].each do |col|
      it { is_expected.to have_db_column col }
    end

    %w[text amount value].each do |col|
      it { is_expected.to validate_presence_of col }
    end
  end

  context "calculations" do
    its(:sub_total) { is_expected.to be_within(0.001).of(subject.amount * subject.value) }
  end
end
