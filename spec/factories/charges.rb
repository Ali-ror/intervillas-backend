FactoryBot.define do
  factory :charge do
    text    { Faker::Lorem.sentence }
    amount  { rand(1..10) }
    value   { (rand(100) * rand).round 2 }
    villa_billing { create :villa_billing, commission: "20" }
  end
end
