FactoryBot.define do
  factory :tag do
    name        { "tag" }
    association :category
    countable   { false }
  end
end
