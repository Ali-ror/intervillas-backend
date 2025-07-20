class BoatsController < ApplicationController
  expose :boat, before: :show do
    Boat.find params[:id]
  end

  expose(:resource) { boat } # für route

  def index
    @boats = Boat.visible
    respond_to do |format|
      format.html
      format.json {render json: @boats.map {|boat| 
      {
        id:boat.id,
        model: boat.model,
        name: boat.boat_name_builder,
        teaser_price: boat.teaser_price,
        horse_power: boat.horse_power,
        main_image_url: boat.main_image,
        images: boat.images.map {|img| {
          url: media_url(img, preset: :teaser)
        }},
      }}}
    end
  end
end
