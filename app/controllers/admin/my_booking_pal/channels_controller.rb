module Admin
  module MyBookingPal
    class ChannelsController < ApplicationController
      include ::Admin::ControllerExtensions

      layout "admin_bootstrap"
      before_action :check_admin!

      def show
        # TODO: render iframe from MyBookingPal, which allows
        # further configuration
      end
    end
  end
end
