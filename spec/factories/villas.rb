FactoryBot.define do
  sequence :villa_name do |n|
    "Villa-#{n}"
  end

  factory :villa do
    name      { generate(:villa_name) }
    buyable   { false }
    active    { true }
    safe_code { "safe_code" }
    street    { "test villa street" }

    living_area      { 265 }
    pool_orientation { Villa::CARDINAL_DIRECTIONS.sample }

    transient do
      no_domain             { false }
      no_tags               { false }
      high_season_starts_on { nil }
      weekly_prices         { false }
    end

    before(:create) do |villa, evaluator|
      unless evaluator.no_domain
        dom = Domain.find_by(default: true) || create(:domain)
        villa.domains << dom
      end

      unless evaluator.no_tags
        cat        = Category.find_by(name: "highlights") || create(:category, :highlights)
        tag_params = { category: cat, name: "boot", countable: false }
        tag        = Tag.find_by(tag_params) || create(:tag, tag_params)
        tag.translations.find_or_create_by(locale: I18n.locale, name_one: tag_params[:name], description: tag_params[:name])
        villa.tag_with "boot", "highlights", 0
      end
    end

    trait :bookable do
      after(:create) do |villa, evaluator|
        create :villa_price, villa: villa, weekly: evaluator.weekly_prices

        create :area, :bedroom, villa: villa, beds_count: 4
      end
    end

    trait :with_owner do
      association :owner, factory: :contact
    end

    trait :with_manager do
      association :manager, factory: :contact
    end

    after(:build) do |villa|
      allow(villa).to receive :attach_geocode
    end

    trait :with_geocode do
      after(:build) do |villa|
        allow(villa).to receive(:attach_geocode).and_call_original
      end
    end

    trait :high_season do
      high_seasons do
        # Keine Ahnung, warum das hier nochmal notwendig ist
        allow(instance).to receive :attach_geocode

        [association(:high_season, starts_on: high_season_starts_on, villas: [instance])]
      end
    end

    trait :displayable do
      with_image

      after(:create) do |villa|
        category = create :category, :bedrooms
        villa.areas.create! category: category, subtype: "schlafzimmer"

        unless villa.descriptions.pluck(:key).include? "description"
          cat = create(:category, :highlights)
          create(:description, key: "description", category: cat, villa: villa)
        end
      end
    end

    trait :editable do
      after(:create) do |villa|
        cat = create(:category, :highlights)
        create(:description, key: "header", category: cat, villa: villa)
        create(:description, key: "teaser", category: cat, villa: villa)
        create(:description, key: "description", category: cat, villa: villa)

        create :category, :bedrooms
        create :category, :bathrooms
      end
    end

    trait :with_mandatory_boat do
      after(:create) do |villa|
        create :boat, :with_prices, exclusive_for_villa: villa
      end
    end

    trait :with_optional_boat do
      after(:create) do |v|
        boat = create(:boat, :with_prices)
        v.optional_boats << boat
        v.reload
      end
    end

    trait :with_external_boat do
      with_optional_boat

      after(:create) do |v|
        v.optional_boats.first.update owner: create(:user)
      end
    end

    trait :with_descriptions do
      after(:create) do |villa|
        {
          highlights:    [true, %w[header teaser description]],
          bedrooms:      [true, "bedrooms"],
          bathrooms:     [true, "bathrooms"],
          kitchen:       [false, "kitchen"],
          lavatory:      [false, "lavatory"],
          livingroom:    [false, "livingroom"],
          entertainment: [false, "entertainment"],
          outdoor:       [false, "outdoor"],
        }.each do |cat_name, (name_as_trait, description_keys)|
          cat = Category.find_by(name: cat_name) || begin
            name_as_trait ? create(:category, cat_name) : create(:category, name: cat_name)
          end

          [*description_keys].each do |key|
            create(:description, key: key, category: cat, villa: villa)
          end
        end
      end
    end

    trait :with_inquiries do
      after(:create) do |villa|
        2.times do
          FullBookingHelper.create_villa_inquiry \
            villa:      villa,
            start_date: generate(:booking_dates)
        end
      end
    end

    trait :with_weekly_prices do
      weekly_prices { true }
    end

    trait :christmas_discount do
      after(:create) { |v| create :holiday_discount, :christmas, villa: v }
    end

    trait :easter_discount do
      after(:create) { |v| create :holiday_discount, :easter, villa: v }
    end

    trait :special_price do
      after(:create) { |v| v.specials << create(:special) }
    end

    trait :with_image do
      before(:create) do |villa|
        villa.images << build(:image, :active, parent: villa)
      end
    end

    trait :inactive do
      active { false }
    end
  end
end
