require "rails_helper"

RSpec.describe Admin::OccupanciesController do
  render_views
  include_context "as_admin"

  let!(:booking) { create_full_booking_with_boat }
  let(:villa)    { booking.villa }
  let(:boat)     { booking.boat }

  %w[villas boats].each do |type|
    context type.to_s do
      let(:rentable) { send(type.singularize) }

      describe "#index" do
        before { get :index, params: { type: type } }

        it { is_expected.to respond_with :success }
      end

      describe "#show" do
        before { get :show, params: { type: type, id: rentable.to_param } }

        it { is_expected.to respond_with :success }
      end

      describe "#calendar" do
        let(:calendar_params) { { type: type, id: rentable.to_param, year: rentable.rentable_inquiries.first.end_date.year } }

        context "format HTML" do
          before { get :calendar, params: calendar_params }

          it { is_expected.to respond_with_content_type(:html) }
          it { is_expected.to render_template(:calendar) }
        end

        context "format CSV" do
          before { get :calendar, params: calendar_params.merge(format: :csv) }

          it { is_expected.to respond_with_content_type(:csv) }
        end
      end
    end
  end
end
