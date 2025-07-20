require "rails_helper"

RSpec.describe CustomersController do
  render_views

  let(:inquiry) { create_villa_inquiry.inquiry }

  describe "#new" do
    before do
      get :new, params: { token: inquiry.token }
    end

    it { is_expected.to respond_with :success }
  end

  describe "#create" do
    let(:customer_params) { attributes_for(:customer, :with_confirmation) }

    context "valid" do
      before do
        post :create, params: { token: inquiry.token, customer: customer_params }
      end

      it { is_expected.to redirect_to "/inquiries/processing" }
    end

    context "invalid" do
      before do
        post :create, params: { token: inquiry.token, customer: { foo: :bar } }
      end

      it { is_expected.to respond_with :unprocessable_entity }
      it { is_expected.to render_template :new }
    end
  end
end
