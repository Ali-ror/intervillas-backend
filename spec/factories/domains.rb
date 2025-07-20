FactoryBot.define do
  factory :domain do
    sequence(:name) { |n| "domain#{n}.example.com" }

    default       { false }
    multilingual  { true }
    partials      { %w[promo_video buttons_villas_specials usp last_minute testimonials seo_block] }
    brand_name    { "Intervilla Florida" }
    theme         { "intervillas" }
    interlink     { true }

    trait :default_domain do
      name    { "intervillas-florida.com" }
      default { true }
      with_slides
    end

    trait :with_slides do
      transient do
        slide_fixtures { %w[slide-03-xxs.jpg slide-06-xxs.jpg] }
      end

      before(:create) do |domain, evaluator|
        evaluator.slide_fixtures.each do |name|
          domain.slides << build(:slide, parent: domain, fixture: name)
        end
      end
    end
  end
end
