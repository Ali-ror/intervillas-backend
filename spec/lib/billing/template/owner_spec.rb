require "rails_helper"

RSpec.describe Billing::Template::Owner do
  context "Given a Booking with external Boat" do
    let(:booking) { create_full_booking_with_boat with_owner: true }
    let(:inquiry) { booking.inquiry }
    let(:boat_inquiry) { inquiry.boat_inquiry }
    let(:villa_inquiry) { inquiry.villa_inquiry }

    # Der Miet-Zeitraum und -Dauer müssen bei Haus-Abrechnungen denen des
    # villa_inquiries und bei Boot-Abrechnungen denen des boat_inquiries
    # entprechen

    describe "its Boat OwnerBilling" do
      subject(:template) { Billing::Template::Owner.new(boat_owner_billing) }

      before do
        booking.boat.owner = create :contact
        booking.boat.save!
        booking.villa_inquiry.create_billing!(meter_reading_begin: 0, meter_reading_end: 100)
        booking.boat_inquiry.create_billing!
      end

      let(:boat_billing) { inquiry.boat_billings.first }
      let(:boat_owner_billing) { Billing::Owner.new(booking.boat.owner, booking, boat_billing) }

      it "takes start_date from boat_inquiry" do
        expect(template.start_date).to eq boat_inquiry.start_date
      end

      it "takes end_date from boat_inquiry" do
        expect(template.end_date).to eq boat_inquiry.end_date
      end

      it "takes days from boat_inquiry" do
        expect(template.period).to eq boat_inquiry.days
      end
    end

    describe "its Villa OwnerBilling" do
      subject(:template) { Billing::Template::Owner.new(villa_owner_billing) }

      before do
        booking.villa_inquiry.create_billing!(meter_reading_begin: 0, meter_reading_end: 100)
      end

      let(:villa_billing) { inquiry.villa_billings.first }
      let(:villa_owner_billing) { Billing::Owner.new(booking.villa.owner, booking, villa_billing) }

      it "takes start_date from villa_inquiry" do
        expect(template.start_date).to eq villa_inquiry.start_date
      end

      it "takes end_date from villa_inquiry" do
        expect(template.end_date).to eq villa_inquiry.end_date
      end

      it "takes days from villa_inquiry" do
        expect(template.period).to eq villa_inquiry.nights
      end
    end
  end
end
