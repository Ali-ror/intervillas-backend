FactoryBot.define do
  sequence :description_key do |n|
    "text_key_#{n}".to_sym
  end

  factory :description do
    key   { generate(:description_key) }
    text  { Faker::Lorem.sentence }
    association :villa
  end
end
