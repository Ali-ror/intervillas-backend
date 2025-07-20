FactoryBot.define do
  factory :booking_pal_product, class: "MyBookingPal::Product" do
    villa

    skip_remote_save { true }
    sequence(:foreign_id) { |n| 42_000_000 + n }
  end
end
