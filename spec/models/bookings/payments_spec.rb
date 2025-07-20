require "rails_helper"

RSpec.describe Bookings::Payments do
  subject(:deadlines) { booking.payment_deadlines }

  include_context "a full booking"

  its(:deadlines) { is_expected.not_to be_empty }
  it { expect(booking.state).to eq "booked" }

  context "with payment" do
    before do
      create :payment, booking: booking, sum: 123.56, paid_on: Date.current
    end

    its(:paid_total) { is_expected.to be_within(0.001).of 123.56 }

    context "with another payment" do
      before do
        create :payment, booking: booking, sum: 200, paid_on: Date.current
      end

      its(:paid_total) { is_expected.to be_within(0.001).of 323.56 }
    end
  end

  it "acknowledges downpayments as acceptable security" do # rubocop:disable RSpec/MultipleExpectations
    booking.update booked_on: Date.current - 30

    # Anzahlung = 35% v. Gesamt-Betrag,  Minimum für Ack = 70% der Anzahlung
    # noinspection RubyModifiedFrozenObject
    dp_factor   = booking.downpayment_percentage
    ack_factor  = DownpaymentSecurity::REL_THRESHOLD
    downpayment = (dp_factor * ack_factor * booking.clearing.total).ceil! + 1

    # Zahlung ist fällig
    pview = Payment::View.find booking.inquiry_id
    expect(pview.downpayment_overdue?).to be true

    # keine Anzahlung? --> kein Acknowledgement
    expect(pview.acceptable_downpayment_security?).to be false

    # Anzahlung erzeugen
    create :payment, booking: booking, sum: 100, paid_on: booking.booked_on + 8

    # Zahlung ist immer noch fällig, und für Ack immer noch nicht ausreichend
    pview = Payment::View.find booking.inquiry_id
    expect(pview.downpayment_overdue?).to be true
    expect(pview.acceptable_downpayment_security?).to be false

    # Mehr als 70% anzahlen
    create :payment, booking: booking, sum: downpayment - 100, paid_on: booking.booked_on + 9

    # Zahlung ist immer noch fällig, ABER für Ack ausreichend
    pview = Payment::View.find booking.inquiry_id
    expect(pview.downpayment_overdue?).to be true
    expect(pview.acceptable_downpayment_security?).to be true

    # Ack!
    booking.update ack_downpayment: true
    expect(Payment::View.overdue.downpayment_nack.find_by(inquiry_id: booking.inquiry_id)).to be_nil
  end

  describe "#pay_with_bsp1" do
    it "saves Payment Process", :vcr do
      booking.pseudocardpan = "9410010000181846692"
      expect {
        booking.bsp1_payment_processes.authorize("remainder")
      }.to change(Bsp1PaymentProcess, :count).by(1)

      bpp = Bsp1PaymentProcess.last
      expect(bpp.status).to eq "APPROVED"
      expect(bpp.deadline).to eq "remainder"
    end

    it "accepts combined payments" do
      auth = instance_double Bsp1::Authorization,
        :amount= => nil,
        submit:     instance_double(Bsp1::Response, status: "APPROVED", attributes: {})
      allow(Bsp1::Authorization).to receive(:from_inquiry).and_return(auth)

      booking.pseudocardpan = "9410010000181846692"
      expect {
        booking.bsp1_payment_processes.authorize("downpayment+remainder")
      }.to change(Bsp1PaymentProcess, :count).by(1)

      expect(Bsp1::Authorization).to have_received(:from_inquiry).once

      bpp = Bsp1PaymentProcess.last
      expect(bpp.status).to eq "APPROVED"
      expect(bpp.deadline).to eq "downpayment+remainder"
    end
  end
end
