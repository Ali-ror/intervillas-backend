module Admin
  module Devise
    class PasswordsController < ::Devise::PasswordsController
      layout "admin_bootstrap_devise"

      def edit
        self.resource = resource_class.with_reset_password_token(params[:reset_password_token])
        unless resource&.reset_password_period_valid?
          redirect_to new_user_password_path, notice: t("devise.failure.expired_password_reset_link")
          return
        end

        set_minimum_password_length
        resource.reset_password_token = params[:reset_password_token]
      end

      def create
        pparams = resource_params.permit(:email)
        if resource_class.where(pparams).exists?(locked_at: nil)
          super
        else
          redirect_to new_user_session_url, alert: t("devise.failure.locked")
        end
      end
    end
  end
end
