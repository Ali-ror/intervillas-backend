require "rails_helper"

RSpec.describe Reservation do
  it { is_expected.to belong_to :inquiry }

  describe "uses :inquiry_id for its primary key" do
    let!(:reservation) { create :reservation }

    it "finds with :inquiry_id" do
      expect(Reservation.find(reservation.inquiry_id)).to eq reservation
    end
  end
end
