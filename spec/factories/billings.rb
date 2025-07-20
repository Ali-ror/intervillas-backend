FactoryBot.define do
  factory :boat_billing do
    association :boat_inquiry, :with_owner_and_prices, :booked

    commission { boat.owner.commission }
    owner { boat.owner }

    trait :net_owner do
      after :create do |boat_billing|
        boat_billing.owner.update net: true
        boat_billing.owner.reload
      end
    end
  end

  factory :villa_billing do
    villa_inquiry { create :villa_inquiry }
    owner { villa.owner || create(:contact) }

    commission          { owner.commission }
    agency_fee          { 15 }

    energy_pricing      { "usage" }
    energy_price        { 0.12 }
    meter_reading_begin { 65_537 }
    meter_reading_end   { 65_537 + 1234 }

    trait :flat_energy_price do
      energy_pricing      { "flat" }
      energy_price        { 150 }
      meter_reading_begin { nil }
      meter_reading_end   { nil }
    end

    trait :energy_inclusive do
      energy_pricing      { "included" }
      energy_price        { nil }
      meter_reading_begin { nil }
      meter_reading_end   { nil }
    end
  end
end
