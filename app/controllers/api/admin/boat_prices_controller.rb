class Api::Admin::BoatPricesController < ApplicationController
  include Admin::ControllerExtensions

  expose(:boat) { Boat.includes(:holiday_discounts).find params[:id] }

  def update
    prices = Boat::PriceUpdater.new(boat)
    if prices.update(update_params)
      boat.reload
      render :show
    else
      render :json, json: {
        message: prices.errors.to_sentence,
      }, status: :unprocessable_entity
    end
  end

  private

  def update_params
    params.require(:boat_price).permit(
      prices:            %i[id currency value subject amount _destroy],
      holiday_discounts: %i[id description percent days_before days_after _destroy],
    )
  end
end
