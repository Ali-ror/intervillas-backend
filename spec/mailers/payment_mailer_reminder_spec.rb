require "rails_helper"

RSpec.describe PaymentMailer do
  include ActionView::Helpers::NumberHelper

  let(:inquiry) {
    create_full_booking_with_boat(
      boat_state:        :optional,
      with_owner:        true,
      with_manager:      true,
      with_boat_manager: true,
      start_date:        90.days.from_now,
      end_date:          110.days.from_now,
    ).inquiry
  }
  let(:customer)          { inquiry.customer }
  let(:rentables)         { booking.rentable_names.join(" / ") }
  let(:booking)           { inquiry.booking }
  let(:payment_deadlines) { booking.payment_deadlines }
  let(:timecop_dest)      { nil }

  let(:mail) {
    PaymentMailer.payment_reminder \
      inquiry: inquiry,
      to:      customer.email
  }

  shared_examples "payment information" do
    it "includes payment information" do
      [
        ERB::Util.html_escape(customer.salutation),
        rentables,
        booking.number,
        number_to_currency(due_sum),
      ].each do |information|
        expect(mail.body.encoded).to include information
      end
    end
  end

  before do
    Timecop.travel(timecop_dest.to_time) if timecop_dest
  end

  after do
    Timecop.return
  end

  it "renders the headers" do
    expect(mail.from).to include "info@intervillas-florida.com"
    expect(mail.to).to include inquiry.customer.email
    expect(mail.subject).to eq "#{inquiry.number}: Zahlungshinweis - Intervilla"
  end

  context "with downpayment due" do
    let(:due_sum)      { payment_deadlines.downpayment_deadline.due_balance }
    let(:timecop_dest) { booking.booked_on + 8.days }

    include_examples "payment information"
  end

  context "with downpayment and remainder due" do
    let(:due_sum)      { payment_deadlines.remainder_deadline.due_balance }
    let(:timecop_dest) { booking.villa_inquiry.start_date - 2.days }

    include_examples "payment information"
  end

  context "only remainder due" do
    let(:due_sum)      { payment_deadlines.remainder_deadline.due_balance }
    let(:timecop_dest) { booking.villa_inquiry.start_date - 2.days }

    before do
      create :payment,
        sum:     booking.downpayment_percentage * inquiry.clearing.total,
        inquiry: inquiry
    end

    include_examples "payment information"
  end
end
