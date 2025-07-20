FactoryBot.define do
  factory :villa_price do
    transient do
      villa_id { nil }
      weekly   { false }
    end

    base_rate         { 160 }
    additional_adult  { weekly ? 0 : 40 }
    children_under_6  { weekly ? 0 :  8 }
    children_under_12 { weekly ? 0 : 18 }
    cleaning          { 42.42 }
    deposit           { 42.42 }

    villa { association :villa, id: villa_id }
  end
end
