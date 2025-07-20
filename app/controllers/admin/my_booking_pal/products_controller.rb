module Admin
  module MyBookingPal
    class ProductsController < ApplicationController
      include ::Admin::ControllerExtensions

      layout "admin_bootstrap"
      before_action :check_admin!

      expose(:product) { ::MyBookingPal::Product.includes(:villa).find params[:id] }
      expose(:villas)  { Villa.active.includes(:booking_pal_product).order(:name) }
      expose(:villa)   { Villa.active.find params[:villa_id] }

      expose(:update_progress) { ::MyBookingPal::UpdateProgress.all }

      def show
        respond_to do |format|
          format.html
          format.json { render :json, json: product.progress }
        end
      end

      def create
        product = villa.create_booking_pal_product!

        flash[:notice] = t("admin.my_booking_pal.products.creating")
        redirect_to admin_my_booking_pal_product_url(product)
      end

      def update
        if params[:step]
          product.update_remote_step!(params[:step])
        else
          product.update_remote_full!
        end

        render :json, json: product.progress
      end

      def destroy
        product.destroy!

        flash[:notice] = t "admin.my_booking_pal.products.deleting",
          villa: product.villa.admin_display_name

        # `redirect_to` would be nicer, but Axios converts that to a
        # `DELETE /admin/my_booking_pal/products` request...
        render :json, json: {
          location: admin_my_booking_pal_products_url,
        }
      end
    end
  end
end
