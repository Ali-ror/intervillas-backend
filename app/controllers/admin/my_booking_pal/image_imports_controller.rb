module Admin
  module MyBookingPal
    class ImageImportsController < ApplicationController
      include ::Admin::ControllerExtensions

      layout "admin_bootstrap"
      before_action :check_admin!

      expose(:product) { ::MyBookingPal::Product.includes(:villa).find params[:product_id] }
      expose(:images)  { product.image_imports.includes(medium: { image_attachment: :blob }) }

      def create
        product.sync_remote_images!
        render :index
      end
    end
  end
end
