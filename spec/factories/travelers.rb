FactoryBot.define do
  factory :traveler do
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    sequence(:born_on) { |n| rand(20..80).years.ago - n.days }

    inquiry { association :inquiry, :with_villa_inquiry }

    trait :children_under_12 do
      price_category { :children_under_12 }
      born_on { (start_date || inquiry.start_date) - rand(8..10).years }
    end
  end
end
