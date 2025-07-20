class Api::Admin::BookingsController < ApplicationController
  include Admin::ControllerExtensions
  include Api::Admin::Common

  def index
    render json: bookings + blockings
  end

  private

  def bookings
    select(Booking)
  end
end
