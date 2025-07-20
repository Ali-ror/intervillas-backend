require "rails_helper"

RSpec.describe Admin::SpecialsController, vcr: { cassette_name: "villa/geocode" } do
  render_views

  describe "logged in" do
    before { sign_in_admin }

    describe "given a villa" do
      before do
        @villa ||= create(:villa)
      end

      describe "with an special" do
        before do
          @special ||= create(:special)
        end

        describe "on GET to :index" do
          before do
            get :index
          end

          it { is_expected.to assign_to(:specials) }
          it { is_expected.to render_template(:index) }
        end

        describe "on GET to :edit" do
          before do
            get :edit, params: { id: @special.to_param }
          end

          it { is_expected.to assign_to(:special).with(@special) }
          it { is_expected.to render_template(:edit) }
        end

        describe "on successfull PUT to :update" do
          before do
            put :update, params: { id: @special.to_param, special: { description: "foo" } }
          end

          it { expect(@special.reload.description).to eq "foo" }
          it { is_expected.to redirect_to(admin_specials_path) }
        end

        describe "on not successfull PUT to :update" do
          before do
            put :update, params: { id: @special.to_param, special: { description: nil } }
          end

          it { is_expected.to render_template(:edit) }
          it { is_expected.to respond_with :unprocessable_entity }
        end
      end
    end
  end
end
