FactoryBot.define do
  factory :inquiry do
    currency { Currency::EUR }
    external { false }

    transient do
      start_date { generate(:booking_dates) }
      end_date   { start_date + 8.days }
      villa      { create :villa, :bookable }
    end
    association :customer

    trait :with_villa_inquiry do
      after(:build) do |inquiry, evaluator|
        build :villa_inquiry,
          start_date: evaluator.start_date,
          end_date:   evaluator.end_date,
          villa:      evaluator.villa,
          inquiry:    inquiry
      end
    end

    trait :with_optional_boat do
      villa { create :villa, :with_optional_boat, :bookable }
      with_boat_inquiry
    end

    trait :with_mandatory_boat do
      villa { create :villa, :with_mandatory_boat, :bookable }
      with_boat_inquiry
    end

    trait :with_boat_inquiry do
      boat_inquiry {
        build :boat_inquiry,
          start_date: start_date + 1.day,
          end_date:   end_date - 1.day,
          boat:       villa.boats.first
      }
    end

    trait :in_dollars do
      currency { Currency::USD }
    end

    trait :booked do
      after(:create) do |inquiry|
        create :base_booking,
          inquiry:    inquiry,
          summary_on: Date.current.beginning_of_month
        inquiry.reload
      end
    end

    trait :external do
      external { true }
    end
  end
end
