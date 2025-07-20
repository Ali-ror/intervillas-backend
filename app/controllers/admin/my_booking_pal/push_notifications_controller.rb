module Admin
  module MyBookingPal
    class PushNotificationsController < ApplicationController
      include ::Admin::ControllerExtensions

      layout "admin_bootstrap"
      before_action :check_admin!

      def show
        respond_to do |format|
          format.html
          format.json
        end
      end

      def update
        base = params.require(:push_notification).fetch(:base_url)
        ::MyBookingPal.client.update_info(base_url: base)

        render "show"
      end
    end
  end
end
