module Admin
  module MyBookingPal
    # Controller is read from at two locations:
    # - the BlockingsCtrl#show action embeds the reservations for a single Blocking
    # - the MyBookingPal::ProductsCtrl#show embeds the reservations for a Product (Villa)
    class ReservationsController < ApplicationController
      include ::Admin::ControllerExtensions

      layout "admin_bootstrap"
      before_action :check_admin!

      expose(:reservations) do
        if params[:inquiry_id]
          # /admin/blockings/:blocking_id/booking_pal_reservations(/:id)
          inquiry.booking_pal_reservations.includes(:product)
        elsif params[:product_id]
          # /admin/my_booking_pal/products/:product_id/reservations(/:id)
          product.reservations.includes(:inquiry)
        else
          # /admin/my_booking_pal/reservations(/:id)
          ::MyBookingPal::Reservation::Base.includes(:inquiry, :product)
        end
      end

      expose(:product)     { ::MyBookingPal::Product.find params[:product_id] }
      expose(:inquiry)     { Inquiry.find params[:inquiry_id] }
      expose(:reservation) { reservations.find params[:id] }

      expose(:pagination) do
        page     = params.fetch("page", 1).to_i
        per_page = params[:inquiry_id] || params[:product_id] ? 15 : 50

        reservations.order(created_at: :desc).limit(per_page).offset((page - 1) * per_page)
      end
    end
  end
end
