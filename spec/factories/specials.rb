FactoryBot.define do
  factory :special do
    description { "test" }
    percent     { 10 }
    start_date  { Date.current }
    end_date    { Date.current + 14.days }
  end
end
