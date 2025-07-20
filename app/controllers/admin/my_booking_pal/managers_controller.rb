module Admin
  module MyBookingPal
    class ManagersController < ApplicationController
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
        ::MyBookingPal.client.update_pm(data: params.require(:manager).to_unsafe_h)

        render "show"
      end
    end
  end
end
