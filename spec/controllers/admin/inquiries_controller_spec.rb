require "rails_helper"

RSpec.describe Admin::InquiriesController do
  include_context "as_admin"
  render_views

  describe "#index" do
    before do
      create_villa_inquiry
      get :index
    end

    it { is_expected.to respond_with :success }
  end

  describe "#new" do
    before do
      get :new
    end

    it { is_expected.to respond_with :success }
  end

  let(:inquiry) { create_villa_inquiry.inquiry }

  describe "#destroy" do
    before do
      delete :destroy, params: { id: inquiry.id }
    end

    it { is_expected.to respond_with :redirect }
  end

  describe "#edit" do
    before do
      get :edit, params: { id: inquiry.id }
    end

    it { is_expected.to respond_with :success }
  end

  describe "#mail" do
    before do
      post :mail, params: { id: inquiry.id }
    end

    it { is_expected.to respond_with :redirect }
  end

  describe "#search_by_id" do
    before do
      get :search_by_id, params: { id: inquiry.id }
    end

    it { is_expected.to redirect_to edit_admin_inquiry_path(inquiry) }
  end

  describe "#search_name" do
    before do
      get :search_name, params: { name: inquiry.customer.last_name }
    end

    it { is_expected.to redirect_to edit_admin_inquiry_path(inquiry) }
  end
end
