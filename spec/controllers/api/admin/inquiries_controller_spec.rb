require "rails_helper"

RSpec.describe Api::Admin::InquiriesController do
  render_views
  include_context "as_admin"

  describe "#index" do
    before do
      inquiry = create_villa_inquiry.inquiry

      get :index, params: {
        villa:   inquiry.villa.to_param,
        between: {
          start: inquiry.start_date - 1.week,
          end:   inquiry.end_date + 1.week,
        },
      }
    end

    it { is_expected.to respond_with :success }
  end
end
