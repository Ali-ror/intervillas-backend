FactoryBot.define do
  # Baut BoatInquiry mit Inquiry und VillaInquiry
  # Standardmäßig wird eine Anfrage für ein Optionales Boot gebaut
  #
  factory :boat_inquiry do
    transient do
      # Die Villa (für das o.g. VillaInquiry), zu dem das optionale Boot gehört
      villa { create :villa, :bookable, :with_optional_boat }
    end

    start_date { generate(:booking_dates) }
    end_date { start_date + 6.days }

    boat { villa.boats.first }
    inquiry { association :inquiry, :with_villa_inquiry, villa: villa, boat_inquiry: instance }

    trait :with_owner_and_prices do
      association :boat, :with_owner, :with_prices
    end

    trait :booked do
      association :inquiry, :booked
    end

    # Baut BoatInquiry (, Inquiry und VillaInquiry) über ein Inklusiv-Boot
    trait :mandatory do
      villa { create :villa, :bookable, :with_mandatory_boat }
      boat { villa.inclusive_boat }
    end
  end
end
