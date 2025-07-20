module Admin
  module Devise
    module SecondFactorAuthentication
      extend ActiveSupport::Concern

      included do
        before_action :authenticate_with_second_factor, if: -> {
          action_name == "create" && otp_enabled_for_user?
        }
      end

      private

      def authenticate_with_second_factor
        user = self.resource = find_user

        if user_params[:otp_attempt].present? && session[:otp_user_id]
          authenticate_user_with_second_factor!(user)
        elsif user&.valid_password?(user_params[:password])
          prompt_for_otp_two_factor(user)
        end
      end

      def valid_otp_attempt?(user)
        user.validate_and_consume_otp!(user_params[:otp_attempt]) ||
          user.invalidate_otp_backup_code!(user_params[:otp_attempt])
      end

      def prompt_for_otp_two_factor(user)
        @user = user

        session[:otp_user_id] = user.id
        render "admin/devise/sessions/otp"
      end

      def authenticate_user_with_second_factor!(user)
        if valid_otp_attempt?(user)
          # Remove any lingering user data from login
          session.delete(:otp_user_id)

          user.save!
          sign_in(user, event: :authentication)
        else
          flash.now[:alert] = t("devise.two_factor.invalid_otp")
          prompt_for_otp_two_factor(user)
        end
      end

      def user_params
        params.require(:user).permit(:email, :password, :otp_attempt)
      end

      def find_user
        if session[:otp_user_id]
          User.find(session[:otp_user_id])
        elsif user_params[:email]
          User.find_by(email: user_params[:email])
        end
      end

      def otp_enabled_for_user?
        find_user&.otp_required_for_login?
      end
    end
  end
end
