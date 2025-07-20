FactoryBot.define do
  sequence :booking_dates do |n|
    # avoid xmas - MINIMUM_BOOKING_NIGHTS turns out to be a very special case
    # most specs are not prepared for
    d = Date.current.beginning_of_year + 1.year + n.days
    d.month == 12 ? d + 1.month : d
  end

  factory :base_booking, class: "Booking" do
    transient do
      state { "booked" }
    end

    after :create do |booking, evaluator|
      case evaluator.state.to_s
      when "full_payment_received"
        create :payment,
          booking: booking,
          sum:     booking.payment_view.remainder_sum
      when "commission_received"
        create :payment,
          booking: booking,
          sum:     booking.payment_view.downpayment_sum
      when "booked"
        # Hat noch ungespeicherte Änderungen am Token
        booking.inquiry.save
      else
        raise "unsupported state: #{evaluator.state}"
      end
    end
  end

  factory :booking, parent: :base_booking do
    transient do
      start_date  { generate(:booking_dates) }
      end_date    { start_date + 8.days }
      villa       { create :villa, :bookable } # villa braucht Preise (after(:create)-Hook) für insert_prices
    end

    inquiry { build :inquiry, :with_villa_inquiry, villa: villa, start_date: start_date, end_date: end_date }

    trait :with_optional_boat do
      inquiry { build :inquiry, :with_optional_boat, start_date: start_date, end_date: end_date }
      boat_start_date { inquiry.start_date + 1.day }
      boat_end_date   { inquiry.end_date - 1.day }
    end

    trait :external do
      inquiry { build :inquiry, :external, :with_villa_inquiry, villa: villa, start_date: start_date, end_date: end_date }
    end
  end

  factory :booking_minimal, parent: :base_booking do
    trait :with_villa do
      association :inquiry, :with_villa_inquiry, strategy: :build
    end
  end
end
