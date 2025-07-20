require "rails_helper"

RSpec.describe DownpaymentSecurity do
  def security(late, paid_sum, downpayment_sum)
    described_class.new(
      late:            late,
      paid_sum:        paid_sum,
      downpayment_sum: downpayment_sum,
    )
  end

  describe "#acceptable?" do
    it "late bookings is never acceptable" do
      expect(security(true, nil, nil).acceptable?).to be false
    end

    {
      "paid < 500, and < 75%"   => [499.99, 1000, false],
      "paid < 500, but >= 75%"  => [299.99, 400, true],
      "paid >= 500, but < 75%"  => [500.0, 1000, true],
      "paid >= 500, and >= 75%" => [500.0, 600, true],
    }.each do |msg, (paid, downpayment, expected)|
      context msg do
        it "with floats" do
          expect(security(false, paid, downpayment).acceptable?).to be expected
        end

        it "with Currency::Value" do
          paid_euro        = Currency::Value.euro(paid)
          downpayment_euro = Currency::Value.euro(downpayment)

          expect(security(false, paid_euro, downpayment_euro).acceptable?).to be expected
        end
      end
    end
  end
end
