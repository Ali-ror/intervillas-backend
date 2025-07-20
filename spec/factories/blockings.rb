FactoryBot.define do
  factory :blocking do
    comment       { "geblockt für foobar" }
    start_date    { generate(:booking_dates) }
    end_date      { start_date + 2.weeks }
    association :villa

    trait :with_calendar do
      calendar { create :calendar, villa: villa }
    end
  end
end
