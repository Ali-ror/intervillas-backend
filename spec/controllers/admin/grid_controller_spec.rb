require "rails_helper"

RSpec.describe Admin::GridController, vcr: { cassette_name: "booking/geocode" } do
  render_views

  describe "logged in" do
    let(:user) { nil }

    before { authenticate_user user }

    describe "with villa and booking" do
      let(:villa)   { booking.villa }
      let(:booking) { create_full_booking_with_boat boat_state: :optional }

      before do
        villa.owner   = create :contact
        villa.manager = create :contact
        villa.save!
      end

      context "as admin" do
        let(:user) { create :user, :with_password, :with_second_factor, admin: true }

        describe "on GET to :index" do
          before { get :index, params: { month: 2, year: 2011 } }

          it { is_expected.to render_template(:index) }
          it { is_expected.to respond_with(:success) }
        end
      end

      context "as manager" do
        let(:user) { create :user, :with_password, admin: false }

        describe "on GET to :index" do
          before { get :index, params: { month: 2, year: 2011 } }

          it { is_expected.not_to set_flash }
          it { is_expected.to render_template(:index) }
        end
      end
    end
  end
end
