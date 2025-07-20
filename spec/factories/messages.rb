FactoryBot.define do
  factory :message do
    association :inquiry
    association :recipient, factory: :user
    text { "foo text" }

    factory :manager_message do
      template { "note_mail" }
    end

    factory :owner_message do
      template { "owner_booking_message" }
    end
  end
end
