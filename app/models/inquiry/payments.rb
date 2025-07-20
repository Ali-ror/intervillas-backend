module Inquiry::Payments
  extend ActiveSupport::Concern

  included do
    has_many :payments,
      -> { order(paid_on: :asc) }

    has_many :bsp1_responses

    has_many :bsp1_payment_processes,
      extend: Bsp1PaymentProcess::InquiryAssociationExtension
  end

  def ack_downpayment
    terminus&.ack_downpayment
  end

  def ack_downpayment?
    ack_downpayment == true
  end

  def payment_deadlines
    @payment_deadlines ||= PaymentDeadlines.from_inquiry(self)
  end

  def deadline_sum(deadline_name)
    case deadline_name.to_s
    when "downpayment"
      payment_deadlines.downpayment_deadline.due_balance
    when "remainder"
      payment_deadlines.remainder_deadline.due_balance
    when "downpayment+remainder"
      payment_deadlines.due_sum
    else
      raise ArgumentError, "Unknown Deadline Name"
    end
  end

  def calculate_charge(deadline_name)
    calc = PaypalHelper::ChargeCalculator.new :bsp1,
      currency:              currency,
      prices_include_cc_fee: prices_include_cc_fee

    calc.add deadline_sum(deadline_name)
  end
end
