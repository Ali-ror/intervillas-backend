require "rails_helper"

RSpec.describe Admin::UsersController do
  describe "logged in" do
    before { sign_in_admin }

    describe "with an user" do
      let!(:user) { create :user }

      describe "on GET to :edit" do
        before { get :edit, params: { id: user.to_param } }

        it { is_expected.to respond_with(200) }
        it { is_expected.to render_template(:edit) }
      end

      describe "PUT to :update" do
        before { put :update, params: { id: user.to_param, user: attrs } }

        describe "with valid params" do
          let(:attrs) { { "email" => Faker::Internet.email } }

          it { is_expected.to redirect_to(admin_users_path) }
          it { expect(user.reload.email).to eq attrs["email"] }
        end

        describe "with invalid params" do
          let(:attrs) { { "email" => "@@" } }

          it { is_expected.to render_template(:edit) }
          it { expect(user.reload.email).not_to eq "@@" }
        end
      end
    end
  end
end
