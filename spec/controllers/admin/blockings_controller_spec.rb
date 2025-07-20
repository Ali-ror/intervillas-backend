require "rails_helper"

RSpec.describe Admin::BlockingsController do
  render_views
  include_context "as_admin"

  let(:villa) { create :villa }

  let(:new_params) {
    {
      start_date: Date.current,
      end_date:   1.day.from_now.to_date,
      villa_id:   villa.id,
    }
  }

  describe "#new" do
    before do
      get :new, params: new_params
    end

    it { is_expected.to respond_with :success }
  end

  describe "#create" do
    let(:create_params) { new_params.merge(comment: "foobar") }

    before do
      post :create, params: { blocking: create_params }
    end

    it { is_expected.to respond_with :redirect }
  end

  context "given a blocking" do
    let(:blocking) { create :blocking }

    describe "#edit" do
      before do
        get :edit, params: { id: blocking.id }
      end

      it { is_expected.to respond_with :success }
    end

    describe "#update" do
      before do
        patch :update, params: { id: blocking.id, blocking: { comment: "foobar2" } }
      end

      it { is_expected.to respond_with :redirect }
    end

    describe "#destroy" do
      before do
        delete :destroy, params: { id: blocking.id }
      end

      it { is_expected.to respond_with :redirect }
    end

    describe "#show" do
      before do
        get :show, params: { id: blocking.id }
      end

      it { is_expected.to respond_with :success }
    end
  end
end
