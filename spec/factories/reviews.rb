FactoryBot.define do
  factory :review do
    inquiry       { create(:booking).inquiry }
    villa_id      { inquiry.villa.id }
    rating        { rand 1..5 }
    published_at  { nil }
    name          { inquiry.customer.last_name }
    city          { inquiry.customer.city }
    text          { Faker::Lorem.paragraphs(number: rand(1..3)).join("\n\n") }

    trait :published do
      published_at { DateTime.current }
    end
  end
end
