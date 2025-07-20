require "rails_helper"

RSpec.describe Cancellation do
  describe "table layout" do
    let(:booking_columns)       { Booking.columns.map { |c| [c.name, c.type] }.to_h }
    let(:cancellation_extras)   { %w[cancelled_at] }
    let(:cancellation_columns)  { Booking.columns.map { |c| [c.name, c.type] }.to_h.except(*cancellation_extras) }

    it "has the same columns" do
      expect(booking_columns.keys.sort).to eq cancellation_columns.keys.sort
    end

    it "has the same column types" do
      booking_columns.each do |col_name, type|
        expect(cancellation_columns[col_name]).to eq type
      end
    end
  end
end
