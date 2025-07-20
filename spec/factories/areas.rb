FactoryBot.define do
  factory :area do
    association :villa
    association :category

    trait :bedroom do
      category { create :category, :bedrooms }
    end
  end
end
