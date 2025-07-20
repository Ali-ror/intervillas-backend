FactoryBot.define do
  factory :contact do
    gender      { "m" }
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    address     { Faker::Address.street_address }
    zip         { Faker::Address.zip_code }
    city        { Faker::Address.city }
    country     { Faker::Address.country }
    emails      { [Faker::Internet.email(name: "#{first_name} #{last_name}")] }
    phone       { Faker::PhoneNumber.phone_number }

    tax_id_number { nil }
    commission    { 20 }

    trait :with_bank_account do
      bank_account_owner  { [first_name, last_name].join(" ") }
      bank_account_number { rand(10_000...10_000_000_000).to_s }
      bank_code           { rand(10_000_000...100_000_000).to_s }
    end

    trait :with_user do
      after(:build) do |contact|
        contact.users << build(:user, :with_password)
      end
    end
  end
end
