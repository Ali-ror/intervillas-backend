require "rails_helper"

RSpec.describe Admin::BookingsController, vcr: { cassette_name: "booking/geocode" } do
  render_views

  describe "logged in" do
    let(:user) { nil }

    before { authenticate_user user }

    describe "with villa and booking" do
      let(:villa)   { booking.villa }
      let(:booking) { create_full_booking_with_boat boat_state: :optional, with_owner: true, with_manager: true }

      context "as admin" do
        let(:user) { create :user, :with_password, :with_second_factor, admin: true }

        describe "on GET to :index" do
          before do
            booking
            get :index
          end

          it { is_expected.to render_template(:index) }
          it { is_expected.to respond_with(:success) }
          it { is_expected.to render_with_layout :admin_bootstrap }
        end

        describe "on GET to :show" do
          before { get :show, params: { id: booking.id } }

          it { is_expected.to render_template :show }
          it { is_expected.to respond_with :success }
        end

        describe "on GET to :edit" do
          before { get :edit, params: { id: booking.id } }

          it { is_expected.to render_template :edit }
          it { is_expected.to respond_with :success }
        end

        describe "#mail" do
          before do
            post :mail, params: { id: booking.id }
          end

          it { is_expected.to respond_with :redirect }
        end
      end

      context "as manager" do
        let(:user) { create :user, :with_password, admin: false }

        describe "on GET to :index" do
          before { get :index }

          it { is_expected.to render_template(:index) }
          it { is_expected.to respond_with(:success) }
          it { is_expected.to render_with_layout :admin_bootstrap }
        end

        describe "on GET to :edit on managed object" do
          before { get :edit, params: { id: booking.id } }

          it { is_expected.to set_flash.to(I18n.t("devise.failure.access_denied")) }
          it { is_expected.to redirect_to("/admin") }
        end

        describe "on GET to :edit on unmanaged object" do
          before { get :edit, params: { id: create_full_booking.id } }

          it { is_expected.to set_flash.to(I18n.t("devise.failure.access_denied")) }
          it { is_expected.to redirect_to("/admin") }
        end
      end
    end
  end
end
