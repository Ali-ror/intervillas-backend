class Api::Admin::AddressCompletionsController < ApplicationController
  include Admin::ControllerExtensions

  def create
    addr = Geocode.geocoder.locate(params[:query])
    render :json, json: addr.as_json(only: %w[
      street postal_code locality region country latitude longitude
    ])
  rescue Graticule::AddressError
    render :json, json: { error: $!.message }, status: :not_found
  end
end
