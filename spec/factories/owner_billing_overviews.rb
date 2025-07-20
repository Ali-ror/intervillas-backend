FactoryBot.define do
  factory :clearing_report do
    contact
    reference_month { Date.current.beginning_of_month.to_date }
    sent_at         { nil }
  end
end
