module Admin
  module Devise
    class RegistrationsController < ::Devise::RegistrationsController
      include Admin::ControllerExtensions

      skip_before_action :enforce_password_expiry!, only: %i[edit update]

      layout :choose_layout

      def destroy
        raise ActiveRecord::RecordNotFound
      end

      def cancel
        raise ActiveRecord::RecordNotFound
      end

      private

      def current_ability
        @current_ability ||= AdminAbility.new(current_user)
      end

      def choose_layout
        user_signed_in? ? "admin_bootstrap" : "admin_bootstrap_devise"
      end

      def account_update_params
        params.require(:user).permit(:password, :password_confirmation, :current_password)
      end

      def after_update_path_for(user)
        stored_location_for(user) || super
      end
    end
  end
end
