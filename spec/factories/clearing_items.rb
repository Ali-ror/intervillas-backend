FactoryBot.define do
  factory :clearing_item do
    transient do
      time_units { 0 }
    end

    start_date { Date.new(2019, 5, 17) }
    end_date { start_date + time_units.days }
    category { "MyString" }
    price { "9.99" }
    amount { 1 }
    inquiry
  end
end
