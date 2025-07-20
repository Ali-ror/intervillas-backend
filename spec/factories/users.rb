FactoryBot.define do
  factory :user do
    email     { Faker::Internet.email name: [Faker::Name.first_name, Faker::Name.last_name].join(" ") }

    # copy Devise logic % send_unlock_instructions...
    locked_at { Time.now.utc }

    trait :with_contact do
      after :build do |user|
        k = user.contacts.first || build(:contact, emails: [user.email])

        k.bank_account_owner  = user.bank_account_owner if user.bank_account_owner
        k.bank_account_number = user.bank_account_number if user.bank_account_number
        k.bank_code           = user.bank_code if user.bank_code
      end
    end

    trait :with_password do
      password              { Digest::SHA1.hexdigest(email) }
      password_confirmation { Digest::SHA1.hexdigest(email) }
      locked_at             { nil }
    end

    trait :with_bank_account do
      transient do
        bank_account_owner  { [Faker::Name.first_name, Faker::Name.last_name].join(" ") }
        bank_account_number { rand(10_000...10_000_000_000).to_s }
        bank_code           { rand(10_000_000...100_000_000).to_s }
      end
    end

    trait :with_second_factor do
      otp_secret             { User.generate_otp_secret }
      otp_required_for_login { true }
    end
  end
end
