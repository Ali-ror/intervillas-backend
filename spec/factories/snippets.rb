FactoryBot.define do
  factory :snippet do
    sequence(:key)  { |i| "snippet_#{i}" }
    title           { Faker::Lorem.words(number: 7).join(" ") }
    de_content_md   { "" }
    en_content_md   { "" }
  end
end
