module Admin
  module MyBookingPal
    class RequestLogsController < ApplicationController
      include ::Admin::ControllerExtensions

      layout "admin_bootstrap"
      before_action :check_admin!

      def index
        respond_to do |format|
          format.html
          format.json do
            page    = params.fetch("page", 1).to_i
            entries = ::MyBookingPal::Client::RequestLog.fetch(page: page)

            render :json, json: entries
          end
        end
      end
    end
  end
end
