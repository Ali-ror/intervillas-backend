FactoryBot.define do
  sequence :category_name do |n|
    "category #{n}"
  end

  factory :category do
    name { generate(:category_name) }

    initialize_with { Category.find_or_initialize_by(name: name) }

    trait :highlights do
      name { "highlights" }
    end

    trait :bedrooms do
      name           { "bedrooms" }
      multiple_types { %w[schlafzimmer einzimmerwohnung sonstiges] }
    end

    trait :bathrooms do
      name           { "bathrooms" }
      multiple_types { %w[vollbad gaestewc duschbad] }
    end
  end
end
