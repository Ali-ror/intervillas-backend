require "rails_helper"

RSpec.describe Admin::CustomersController do
  include_context "as_admin"
  let(:customer) { create_villa_inquiry.inquiry.customer }
  let(:customer_params) { attributes_for(:customer).merge "currency" => Currency::USD }

  describe "#update" do
    context "valid" do
      before do
        patch :update, params: { id: customer.id, customer: customer_params }
      end

      it { is_expected.to respond_with :redirect }
    end

    context "invalid" do
      before do
        patch :update, params: { id: customer.id, customer: { first_name: "" } }
      end

      it { is_expected.to respond_with :unprocessable_entity }
      it { is_expected.to render_template :edit }
    end
  end
end
