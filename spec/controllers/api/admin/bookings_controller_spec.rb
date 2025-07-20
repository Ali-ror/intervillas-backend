require "rails_helper"

RSpec.describe Api::Admin::BookingsController do
  include_context "as_admin"
  let!(:booking) { create_full_booking }

  describe "#index" do
    before do
      get :index, params: { villa: booking.villa.to_param, between: { start: booking.start_date - 1.week, end: booking.end_date + 1.week } }
    end

    it { is_expected.to respond_with :success }
  end
end
