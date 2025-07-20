FactoryBot.define do
  factory :bsp1_payment_process do
    status { "APPROVED" }

    amount { 1_234_500 }
    handling_fee { 12 }

    booking

    trait :with_reservation do
      booking { nil }
      reservation
    end
  end
end
