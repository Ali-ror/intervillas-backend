FactoryBot.define do
  factory :route do
    name        { "test_route" }
    path        { "test-path" }
    controller  { "test-controller" }
    action      { "test-action" }

    trait :with_villa do
      association :resource, factory: [:villa]
    end
  end
end
