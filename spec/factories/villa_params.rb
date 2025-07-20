FactoryBot.define do
  factory :villa_params, class: "Clearing::VillaParams" do
    initialize_with { Clearing::VillaParams.new }

    villa { create :villa, :bookable }
    adults { 2 }
    start_date { generate(:booking_dates) }
    end_date { start_date + 14.days }
  end
end
