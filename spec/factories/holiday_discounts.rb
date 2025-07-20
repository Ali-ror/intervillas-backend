FactoryBot.define do
  factory :holiday_discount do
    percent     { 20 }
    days_before { 1 }
    days_after  { 14 }

    trait :with_villa do
      association :villa
    end

    trait :christmas do
      description { "christmas" }
    end

    trait :easter do
      description { "easter" }
    end
  end
end
