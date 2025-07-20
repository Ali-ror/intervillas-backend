FactoryBot.define do
  factory :boat_price do
    association :boat

    subject    { "daily" }
    value      { 42.42 }
    created_at { 1.hour.ago }
    amount     { 3 if subject == "daily" }
    currency   { Currency::EUR }
  end
end
