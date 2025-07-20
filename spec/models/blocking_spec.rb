require "rails_helper"

RSpec.describe Blocking do
  it { is_expected.to belong_to(:villa).optional }
  it { is_expected.to belong_to(:boat).optional }
  it { is_expected.to belong_to(:calendar).optional }

  context "a blocking" do
    subject(:blocking) { create :blocking, start_date: Date.current }

    describe "#date_range" do
      it { expect(blocking.date_range).to include Date.tomorrow }
    end
  end

  describe "#id" do
    let(:inquiry)       { create :inquiry }
    let(:blocking)      { create :blocking }
    let(:other_inquiry) { create :inquiry }

    it "shares a sequence with inquiries" do
      expect(inquiry).to be_persisted
      expect(blocking.id).to be > inquiry.id
      expect(other_inquiry.id).to be > blocking.id
    end
  end
end
