require "rails_helper"

RSpec.describe Booking do
  describe "#villa_name" do
    subject(:booking) { build(:booking_minimal, :with_villa) }

    it "should know the villa name" do
      expect(booking.villa_name).to eq booking.villa.name
    end
  end
end
