module Admin
  module Devise
    class SessionsController < ::Devise::SessionsController
      include SecondFactorAuthentication

      skip_before_action :set_sentry_context

      layout "admin_bootstrap_devise"

      def create
        super

        flash[:pw_expiry] = t("admin.password_expiry_banner.warning") if resource.password_expiry_soft_warning?
      end

      def destroy
        return super unless session[:admin]

        user = User.find(session[:admin])
        sign_in user # doesn't update current_user

        session[:admin] = nil
        flash[:notice]  = t(".impersonation_ended", email: user.email)
        redirect_to after_sign_in_path_for(user)
      end

      private

      def after_sign_in_path_for(resource)
        stored_location_for(resource) || overview_path(resource) || signed_in_root_path(resource)
      end

      def after_sign_out_path_for(*)
        new_user_session_url
      end

      def overview_path(resource)
        return unless resource.is_a?(User)

        resource.admin? ? admin_bookings_url : admin_root_url
      end
    end
  end
end
