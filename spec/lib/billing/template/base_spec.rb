require "rails_helper"

RSpec.describe "Billing::Template::Base" do
  let(:booking) { create_full_booking_with_boat with_owner: true }
  let(:villa_owner_billing) { Billing::Owner.new(booking.villa.owner, booking, villa_billing) }
  let(:villa_billing) { booking.inquiry.villa_billings.first }

  before do
    booking.villa_inquiry.create_billing!(meter_reading_begin: 0, meter_reading_end: 100)
  end

  describe "#currency" do
    subject(:template) { Billing::Template::Base.new(villa_owner_billing) }

    it "renders currency" do
      expect(template.format_currency(100.234567)).to eq "\\currency{100,23}"
    end

    it "renders currency with Currency::Value" do
      expect(template.format_currency(Currency::Value.euro(100.234567))).to eq "\\currency{100,23}"
    end
  end
end
