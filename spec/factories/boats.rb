FactoryBot.define do
  factory :boat do
    description { Faker::Lorem.paragraph }
    url         { "http://www.example.com/" }

    sequence(:model)                { |n| format "Hurrican Sundeck %d", 2400 + n }
    sequence(:matriculation_number) { |n| format "%05x", 0x123_F00 | n }

    trait :with_prices do
      with_utilities
      with_daily_prices
    end

    trait :with_daily_prices do
      after(:create) do |boat|
        create :boat_price, boat: boat, subject: "daily", amount: 3, value: 23.23
      end
    end

    trait :with_utilities do
      with_training
      with_deposit
    end

    trait :with_training do
      after(:create) do |boat|
        create :boat_price, boat: boat, subject: "training", value: 150.0
      end
    end

    trait :with_deposit do
      after(:create) do |boat|
        create :boat_price, boat: boat, subject: "deposit", value: 900
      end
    end

    trait :active do
      with_prices
    end

    trait :mandatory do
      association :exclusive_for_villa, factory: :villa
    end

    trait :assigned do
      after(:create) do |boat|
        boat.optional_villas << create(:villa)
      end
    end

    trait :with_owner do
      association :owner, factory: :contact
    end

    trait :with_manager do
      association :manager, factory: :contact
    end
  end
end
