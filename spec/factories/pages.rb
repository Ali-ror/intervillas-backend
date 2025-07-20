FactoryBot.define do
  sequence :page_name do |n|
    format("%s %d", Faker::Lorem.words(number: 2).join(" ").capitalize, n)
  end

  factory :page do
    name    { generate(:page_name) }
    content { Faker::Lorem.paragraph(sentence_count: 4) }
    noindex { false }

    transient do
      no_domain { false }
    end

    before :create do |page, evaluator|
      unless evaluator.no_domain
        dom = Domain.find_by(default: true) || create(:domain)
        page.domains << dom
      end
    end
  end
end
