FactoryBot.define do
  factory :high_season do
    starts_on { Date.new(Date.current.year + 1, 12, 15) }
    ends_on   { Date.new(starts_on.year + 1, 5, 31) }

    trait :with_villa do
      villas { [create(:villa, :bookable)] }
    end
  end
end
