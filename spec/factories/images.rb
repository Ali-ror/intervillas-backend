FactoryBot.define do
  sequence :image_name do |n|
    "image #{n}"
  end

  factory :image, class: "Media::Image" do
    description { generate(:image_name) }

    transient do
      image_file { Rails.root.join("spec/fixtures/file.jpg") }

      after :build do |medium, evaluator|
        fixture = evaluator.image_file

        medium.image.attach(
          io:       fixture.open("rb"),
          filename: fixture.basename.to_s,
        )
      end
    end

    # association :parent, factory: :villa

    trait :active do
      active { true }
    end
  end

  factory :slide, class: "Media::Slide" do
    description { "slide" }
    active      { true }

    transient do
      fixture { nil }

      after :build do |slide, evaluator|
        fixture = Rails.root.join("spec/fixtures", evaluator.fixture)

        slide.slide.attach(
          io:       fixture.open("rb"),
          filename: fixture.basename.to_s,
        )
      end
    end
  end
end
