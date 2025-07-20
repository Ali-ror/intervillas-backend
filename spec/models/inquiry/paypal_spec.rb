require "rails_helper"

RSpec.describe Inquiry::Paypal do
  describe "#create_or_update_paypal_payment! payment" do
    subject(:paypal_payment) do
      inquiry.paypal_payments.find_by(inquiry_id: inquiry.id, transaction_id: sdk_payment.id)
    end

    let!(:inquiry) { create :inquiry }
    let!(:sdk_payment) do
      PayPal::SDK::REST::Payment.new(
        id:           "PAY-FOO",
        state:        "approved",
        create_time:  "2018-06-13T01:14:45Z",
        links:        [
          {
            rel:  "approval_url",
            href: "https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-FOO",
          },
        ],
        transactions: [
          {
            related_resources: [
              {
                sale: {
                  amount: {
                    total:    "945.67",
                    details:  {
                      subtotal:     "910.00",
                      handling_fee: "35.67",
                    },
                    currency: Currency::EUR,
                  },
                },
              },
            ],
          },
        ],
      )
    end

    before do
      inquiry.create_or_update_paypal_payment!(sdk_payment)
    end

    it { expect(paypal_payment.data).to be_kind_of Hash }
    it { expect(paypal_payment.data).to include "id" => "PAY-FOO" }
    it { expect(paypal_payment.transaction_id).to eq "PAY-FOO" }
    it { expect(paypal_payment.transaction_status).to eq "approved" }
    it { expect(paypal_payment.web_token).to eq "EC-FOO" }
    it { expect(paypal_payment.created_at).to eq Time.new(2018, 6, 13, 1, 14, 45, "+00:00") }

    describe "payment" do
      subject(:payment) { inquiry.payments.paypal.last }

      let!(:sdk_payment) do
        PayPal::SDK::REST::Payment.new(
          id:           "PAY-FOO",
          state:        "completed",
          create_time:  "2018-06-13T01:14:45Z",
          update_time:  "2018-06-13T01:14:45Z",
          links:        [
            {
              rel:  "approval_url",
              href: "https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-FOO",
            },
          ],
          transactions: [
            {
              related_resources: [
                {
                  sale: {
                    amount: {
                      total:    "945.67",
                      details:  {
                        subtotal:     "910.00",
                        handling_fee: "35.67",
                      },
                      currency: Currency::EUR,
                    },
                  },
                },
              ],
            },
          ],
        )
      end

      it { expect(payment).to be_paid }
    end
  end
end
