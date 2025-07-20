require "rails_helper"

RSpec.describe Bsp1PaymentProcess do
  it { is_expected.to belong_to(:booking).optional }
  it { is_expected.to belong_to(:reservation).optional }
  it { is_expected.to have_many :bsp1_responses }
  it { is_expected.to have_many(:payments).through(:bsp1_responses) }

  context "after_save" do
    describe "#release_reservation" do
      subject(:bpprocess) { create :bsp1_payment_process, :with_reservation }

      it "removes reservation when status changes to ERROR" do
        expect(bpprocess.reservation).to be_present
        bpprocess.update! status: "ERROR"
        expect(bpprocess.reload.reservation).not_to be_present
      end
    end
  end
end
