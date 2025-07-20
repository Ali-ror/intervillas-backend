require "rails_helper"

RSpec.describe Admin::BoatsController do
  render_views

  describe "logged in" do
    before { sign_in_admin }

    describe "#index" do
      before do
        get :index
      end

      it { is_expected.to respond_with :success }
    end

    describe "on GET to :new" do
      before do
        get :new
      end

      it { is_expected.to respond_with :success }
      it { is_expected.to render_template :new }
    end

    describe "creating a boat" do
      describe "successfull" do
        before do
          post :create, params: { boat: { url: :foo, de_description: "foobar" } }
        end

        it { is_expected.to respond_with :redirect }
      end
    end

    describe "given a boat" do
      let(:boat) { create :boat }

      describe "on GET to :edit" do
        before do
          get :edit, params: { id: boat.id }
        end

        it { is_expected.to respond_with :success }
        it { is_expected.to render_template(:edit) }
      end

      describe "updating a boat" do
        describe "successful update" do
          before do
            allow_any_instance_of(Boat).to receive(:update).and_return(true)
            put :update, params: { id: boat.id, boat: { url: Faker::Internet.url } }
          end

          it { is_expected.to set_flash.to(/erfolgreich gespeichert/) }
          it { is_expected.to redirect_to(edit_admin_boat_path(boat)) }
        end

        describe "not successful update" do
          before do
            put :update, params: { id: boat.id, boat: { de_description: "" } }
          end

          it { is_expected.to set_flash }
          it { is_expected.to render_template(:edit) }
        end
      end

      describe "#destroy" do
        before do
          delete :destroy, params: { id: boat.id }
        end

        it { is_expected.to redirect_to admin_boats_path }
      end
    end
  end
end
