FactoryBot.define do
  factory :customer do
    locale      { "de" }
    title       { "Herr" }
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    email       { Faker::Internet.email(name: "#{first_name} #{last_name}") }
    address     { Faker::Address.street_address }
    appnr       { Faker::Address.building_number }
    postal_code { Faker::Address.zip_code }
    city        { Faker::Address.city }
    country     { Faker::Address.country_code }
    phone       { Faker::PhoneNumber.phone_number }

    trait :with_confirmation do
      email_confirmation { email }
    end
  end
end
