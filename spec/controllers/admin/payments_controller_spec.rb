require "rails_helper"

RSpec.describe Admin::PaymentsController, vcr: { cassette_name: "villa/geocode" } do
  render_views

  context "unauthorized" do
    context "on GET to :index" do
      before do
        get :index
      end

      it { is_expected.to respond_with :found }
      it { is_expected.to redirect_to "/admin/users/sign_in" }
    end
  end

  context "authorized" do
    before { sign_in_admin }

    let(:booking) { create_full_booking }
    let(:inquiry) { booking.inquiry }
    let(:payment) { create :payment, booking: booking }

    context "on GET to :index" do
      before do
        get :index
      end

      it { is_expected.to assign_to :payments }
      it { is_expected.to respond_with :success }
      it { is_expected.to render_template :index }
      it { is_expected.to render_with_layout :admin_bootstrap }
    end

    context "on GET to :edit" do
      before do
        get :edit, params: { inquiry_id: inquiry.id, id: payment.id }
      end

      it { is_expected.to assign_to :payment }
      it { is_expected.to respond_with :success }
      it { is_expected.to render_template :edit }
    end

    context "on successful PATCH to :update" do
      before do
        patch :update, params: { inquiry_id: inquiry.id, id: payment.id, payment: { paid_on: Date.current, sum: 123.45 } }
      end

      it { is_expected.to assign_to :payment }
      it { is_expected.to redirect_to [:edit, :admin, booking, { anchor: "payments" }] }
    end

    context "on not successful PATCH to :update" do
      before do
        patch :update, params: { inquiry_id: inquiry.id, id: payment.id, payment: { paid_on: :foo, sum: 0 } }
      end

      it { is_expected.to assign_to :payment }
      it { is_expected.to render_template :edit }
    end

    context "on GET to :balance" do
      let!(:payments) { create_list :payment, 2, paid_on: Faker::Date.in_date_period(year: 2021) }
      let!(:payments_us) { create_list :payment, 2, paid_on: Faker::Date.in_date_period(year: 2021), currency: Currency::USD }

      context "html" do
        before do
          get :balance, params: { year: 2021 }
        end

        it { is_expected.to respond_with :success }
      end

      context "csv" do
        before do
          get :balance, params: { year: 2021, format: :csv }
        end

        it { is_expected.to respond_with :success }
      end
    end
  end
end
