require "rails_helper"

RSpec.describe Admin::PreviewsController do
  render_views

  context "with villa and booking" do
    let(:booking) { create_full_booking_with_boat boat_state: :optional }
    let(:villa)   { booking.villa }

    context "logged_in" do
      before { authenticate_user user }

      context "as admin" do
        let(:user) { create :user, :with_password, :with_second_factor, admin: true }

        describe "on GET to :preview" do
          before do
            get :show, params: { id: booking.id, mailer_class: "BookingMailer", mailer_action: "confirmation_mail" }
          end

          it { is_expected.to render_template "booking_mailer/confirmation_mail" }
          it { is_expected.to respond_with :success }
        end
      end

      context "as manager" do
        let(:user) { create :user, :with_password, admin: false }

        describe "on GET to :preview" do
          before do
            get :show, params: { id: booking.id, mailer_class: "BookingMailer", mailer_action: "confirmation_mail" }
          end

          it { is_expected.to set_flash.to(I18n.t("devise.failure.access_denied")) }
          it { is_expected.to redirect_to("/admin") }
        end
      end
    end
  end
end
