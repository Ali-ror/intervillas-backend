FactoryBot.define do
  factory :payment do
    sum     { 1234.56 }
    inquiry { nil }
    scope   { nil }
    paid_on { Date.current }

    transient do
      booking { false }
      currency { Currency::EUR }
    end

    after :build do |payment, evaluator|
      payment.inquiry = evaluator.booking.inquiry if evaluator.booking

      payment.inquiry ||= FullBookingHelper.create_full_booking(currency: evaluator.currency).inquiry
    end
  end
end
