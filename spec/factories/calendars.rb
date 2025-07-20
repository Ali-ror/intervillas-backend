FactoryBot.define do
  factory :calendar do
    association :villa
    url { Faker::Internet.url }
  end
end
