require "rails_helper"

RSpec.describe PaymentMailer do
  include ActionView::Helpers::NumberHelper

  let(:inquiry) do
    create_full_booking_with_boat(
      boat_state:        :optional,
      with_owner:        true,
      with_manager:      true,
      with_boat_manager: true,
    ).inquiry
  end
  let(:customer)          { inquiry.customer }
  let(:rentables)         { booking.rentable_names.join(" / ") }
  let(:booking)           { inquiry.booking }
  let(:payment_deadlines) { booking.payment_deadlines }
  let(:due_sum)           { payment_deadlines.remainder_deadline.due_balance }

  let(:mail) do
    PaymentMailer.payment_prenotification \
      inquiry: inquiry,
      to:      customer.email
  end

  before do
    create :payment,
      sum:     booking.downpayment_percentage * booking.clearing.total,
      inquiry: inquiry
  end

  it "renders the headers" do
    expect(mail.from).to include "info@intervillas-florida.com"
    expect(mail.to).to include inquiry.customer.email
    expect(mail.subject).to eq "#{inquiry.number}: Hinweis auf anstehendes Zahlungsziel - Intervilla"
  end

  it "includes payment information" do
    body = mail.body.encoded
    [
      ERB::Util.html_escape(customer.salutation),
      rentables,
      booking.number,
      number_to_currency(due_sum),
      "PayPal",
      "Kreditkarte",
    ].each do |information|
      expect(body).to include information
    end
  end
end
