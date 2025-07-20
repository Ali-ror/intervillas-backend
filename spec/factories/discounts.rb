FactoryBot.define do
  factory :discount do
    subject      { "christmas" }
    value        { 20 }
    inquiry_kind { :villa }
    period       { Date.new(2017, 12, 24)..Date.new(2018, 1, 3) }
  end
end
