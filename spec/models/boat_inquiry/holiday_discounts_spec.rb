require "rails_helper"

RSpec.describe BoatInquiry do
  it { is_expected.to have_many :discounts }

  context "over easter" do
    subject(:boat_inquiry) { create :boat_inquiry, boat: boat, start_date: date }

    let(:date) { Date.easter(Time.current.year + 1) - 3 }
    let(:boat) { create :boat, :with_prices }

    its(:discounts) { is_expected.to be_empty }

    context "with holiday discount" do
      let!(:easter_discount) { create :holiday_discount, :easter, boat: boat }
      let(:discount) { subject.discounts.first }

      its(:discounts) { is_expected.not_to be_empty }

      describe "actual discounts" do
        subject { boat_inquiry.discounts }

        its(:count) { is_expected.to eq 1 }
        its(:first) { is_expected.to have_attributes inquiry_id: boat_inquiry.inquiry_id, subject: "easter" }
      end

      context "created after the booking" do
        let!(:easter_discount) { create :holiday_discount, :easter, boat: boat, created_at: 2.years.from_now }

        its(:discounts) { is_expected.to be_empty }
      end
    end
  end
end
