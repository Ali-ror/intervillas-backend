require "rails_helper"

RSpec.describe BlockingForm do
  subject(:blocking_form) { BlockingForm.new }

  it { is_expected.to validate_presence_of :comment }

  describe ".validates ends_after_start" do
    subject(:form) { BlockingForm.new(start_date: Date.tomorrow, end_date: end_date) }

    include_examples "validates_ends_after_start"
  end

  describe ".validates already_booked" do
    subject(:form) { BlockingForm.new(villa_id: villa.id, start_date: clashing_booking.start_date, end_date: clashing_booking.end_date) }

    include_examples "validates_availability"
  end
end
