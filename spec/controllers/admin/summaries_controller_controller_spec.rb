require "rails_helper"

RSpec.describe Admin::SummariesController do
  render_views

  describe "as admin" do
    before { sign_in_admin }

    include_context "prepare billings"

    it "#index" do
      booking.update summary_on: Date.current.beginning_of_month
      get :index
      expect(response).to have_http_status 200
    end
  end
end
