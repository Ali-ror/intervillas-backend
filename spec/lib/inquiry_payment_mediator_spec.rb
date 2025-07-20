require "rails_helper"

RSpec.describe InquiryPaymentMediator, vcr: { record: :none } do
  let(:villa) { create :villa, :bookable }
  let(:downpayment) { ipm("downpayment").payment_hash }
  let(:remainder)   { ipm("remainder").payment_hash }
  let(:booking)     { create_full_booking(villa: villa, start_date: start_date) }
  let(:inquiry)     { booking.inquiry }

  def ipm(modus)
    InquiryPaymentMediator.new(inquiry).tap { |ipm| ipm.modus = modus }
  end

  shared_examples "paypal fields" do |name, price, handling, total|
    context "for #{name}" do
      its([:intent]) { is_expected.to eq "sale" }
      its([:payer])  { is_expected.to eq(payment_method: "paypal") }

      its([:application_context]) do
        is_expected.to eq(
          brand_name:          "Intervilla Corp.",
          locale:              "de_DE",
          landing_page:        "Billing",
          shipping_preference: "NO_SHIPPING",
          user_action:         "commit",
          payment_pattern:     "CUSTOMER_PRESENT_ONETIME_PURCHASE",
        )
      end

      its([:transactions]) {
        is_expected.to eq([{
          reference_id: inquiry.number,
          item_list:    {
            items: [{
              url:      "http://localhost:5051/inquiries/#{inquiry.token}/confirmation",
              name:     "#{inquiry.number} #{name}",
              currency: Currency::EUR,
              quantity: 1,
              price:    price,
            }],
          },
          amount:       {
            currency: Currency::EUR,
            total:    total,
            details:  {
              subtotal:     price,
              handling_fee: handling,
            },
          },
        }])
      }
    end
  end

  describe "20% downpayment (legacy)" do
    let(:start_date) do
      year = PaymentDeadlines::DOWNPAYMENT_PERCENTAGE_CHANGED_ON.year - 1
      "#{year}-06-01".to_date
    end

    # for downpayment due date calculation, booking must be in the future
    around { |ex| Timecop.travel(start_date - 6.months, &ex) }

    context "when nothing paid yet" do
      describe "#payment_hash" do
        it_behaves_like "paypal fields", "Anzahlung", "240.00", "8.81", "248.81" do
          subject { downpayment }
        end

        it_behaves_like "paypal fields", "Restzahlung", "1204.84", "42.77", "1247.61" do
          subject { remainder }
        end
      end
    end

    context "when downpayment fully paid" do
      before { create :payment, sum: 250, inquiry: inquiry }

      describe "#payment_hash" do
        it { expect { downpayment }.to raise_error InquiryPaymentMediator::NothingToPay }

        it_behaves_like "paypal fields", "Restzahlung", "954.84", "33.97", "988.81" do
          subject { remainder }
        end
      end
    end

    context "when downpayment partially paid" do
      before { create :payment, sum: 100, inquiry: inquiry }

      describe "#payment_hash" do
        it_behaves_like "paypal fields", "Anzahlung", "140.00", "5.29", "145.29" do
          subject { downpayment }
        end

        it_behaves_like "paypal fields", "Restzahlung", "1104.84", "39.25", "1144.09" do
          subject { remainder }
        end
      end
    end

    context "when part of remainder paid" do
      before { create :payment, sum: 350, inquiry: inquiry }

      describe "#payment_hash" do
        it { expect { downpayment }.to raise_error InquiryPaymentMediator::NothingToPay }

        it_behaves_like "paypal fields", "Restzahlung", "854.84", "30.45", "885.29" do
          subject { remainder }
        end
      end
    end

    context "when fully paid" do
      before { create :payment, sum: 1204.84, inquiry: inquiry }

      describe "#payment_hash" do
        it { expect { downpayment }.to raise_error InquiryPaymentMediator::NothingToPay }
        it { expect { remainder }.to raise_error InquiryPaymentMediator::NothingToPay }
      end
    end
  end

  context "35% downpayment" do
    let(:start_date) { "#{Date.current.year + 1}-06-01".to_date }

    context "when nothing paid yet" do
      describe "#payment_hash" do
        it_behaves_like "paypal fields", "Anzahlung", "410.00", "14.79", "424.79" do
          subject { downpayment }

          # reicht, wenn einmal getestet
          its([:redirect_urls]) do
            is_expected.to include(
              return_url: match(%r{.*/complete$}),
              cancel_url: match(%r{.*/cancel$}),
            )
          end
        end

        it_behaves_like "paypal fields", "Restzahlung", "1204.84", "42.77", "1247.61" do
          subject { remainder }
        end
      end
    end

    context "when downpayment fully paid" do
      before { create :payment, sum: 430, inquiry: inquiry }

      describe "#payment_hash" do
        it { expect { downpayment }.to raise_error InquiryPaymentMediator::NothingToPay }

        it_behaves_like "paypal fields", "Restzahlung", "774.84", "27.63", "802.47" do
          subject { remainder }
        end
      end
    end

    context "when downpayment partially paid" do
      before { create :payment, sum: 100, inquiry: inquiry }

      describe "#payment_hash" do
        it_behaves_like "paypal fields", "Anzahlung", "310.00", "11.27", "321.27" do
          subject { downpayment }
        end

        it_behaves_like "paypal fields", "Restzahlung", "1104.84", "39.25", "1144.09" do
          subject { remainder }
        end
      end
    end

    context "when part of remainder paid" do
      before { create :payment, sum: 450, inquiry: inquiry }

      describe "#payment_hash" do
        it { expect { downpayment }.to raise_error InquiryPaymentMediator::NothingToPay }

        it_behaves_like "paypal fields", "Restzahlung", "754.84", "26.93", "781.77" do
          subject { remainder }
        end
      end
    end

    context "when fully paid" do
      before { create :payment, sum: 1204.84, inquiry: inquiry }

      describe "#payment_hash" do
        it { expect { downpayment }.to raise_error InquiryPaymentMediator::NothingToPay }
        it { expect { remainder }.to raise_error InquiryPaymentMediator::NothingToPay }
      end
    end
  end
end
