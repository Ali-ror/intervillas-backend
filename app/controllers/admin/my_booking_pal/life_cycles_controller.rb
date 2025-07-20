module Admin
  module MyBookingPal
    class LifeCyclesController < ApplicationController
      include ::Admin::ControllerExtensions

      layout "admin_bootstrap"
      before_action :check_admin!

      expose(:product) { ::MyBookingPal::Product.find params[:product_id] }

      def update
        product.update_remote_lifecycle!(params[:value])
        product.reload

        render "show"
      end
    end
  end
end
