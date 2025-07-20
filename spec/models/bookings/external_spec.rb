require "rails_helper"

RSpec.describe "Bookings::External" do
  describe ".internal" do
    subject(:bookings) { Booking.internal }

    let(:external) { create :booking, :external }
    let(:internal) { create :booking }

    it "includes only internal bookings" do
      expect(bookings).to include internal
      expect(bookings).not_to include external
    end
  end
end
