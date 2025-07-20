class Api::Admin::BoatOccupanciesController < ApplicationController
  include Admin::ControllerExtensions

  expose(:inquiry_id)  { params.fetch(:id).to_i }
  expose(:boat_finder) { BoatFinder.new(inquiry_id) }

  def show
    render json: boat_finder
  end
end
