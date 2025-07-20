FactoryBot.define do
  factory :villa_inquiry do
    transient do
      currency { Currency::EUR }
      external { false }

      # Reisende können direkt als Traveler-Objekte übergeben werden. Diese werden
      # an das Inquiry weitergereicht.
      travelers { [] }
    end

    inquiry { association :inquiry, currency: currency, travelers: travelers, external: external }

    start_date        { generate(:booking_dates) }
    end_date          { start_date + 14.days }
    adults            { 2 }
    children_under_12 { 0 }

    association :villa, :bookable

    # VillaInquiry in der Hochsaison erstellen
    # Der komplette Reisezeitraum liegt standardmäßig in der Hochsaison
    trait :high_season do
      villa { association :villa, :bookable, :high_season, high_season_starts_on: start_date }
    end

    # Die gebuchte Villa soll über ein optionals Boot verfügen.
    # Das Boot wird NICHT automatisch auch gebucht.
    trait :villa_with_optional_boat do
      association :villa, :bookable, :with_optional_boat
    end

    # Es soll das alte Preismodell (spezifischer Übernachtungspreis pro Belegung) verwendet werden.
    trait :legacy_prices do
      inquiry { association :inquiry, currency: currency, travelers: travelers, strategy: :create }

      # HACK: ein ClearingItem für :adults erstellen, um die alte Preisstruktur
      # zu benutzen
      clearing_items { [association(:clearing_item, inquiry: inquiry, category: "adults")] }
    end

    before :create do |vi, evaluator|
      if evaluator.travelers.blank?
        evaluator.adults.times do
          vi.inquiry.travelers << build(:traveler, inquiry: vi.inquiry, start_date: vi.start_date, end_date: vi.end_date)
        end
        evaluator.children_under_12.times do
          traveler = build(:traveler, :children_under_12, inquiry: vi.inquiry, start_date: vi.start_date, end_date: vi.end_date)
          Rails.logger.error { traveler.errors.inspect } unless traveler.valid?

          vi.inquiry.travelers << traveler
        end
      end

      Rails.logger.error { vi.inquiry.errors.inspect } unless vi.inquiry.valid?
    end
  end
end
