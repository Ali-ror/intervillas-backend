class MapsController < ApplicationController
  helper_method :resource

  # POST /villas/:villa_id/map
  # POST /karte
  def api_key
    if params[:villa_id].present?
      map_for_villa Villa.find(params[:villa_id])
    else
      map_for_overview
    end
  end

  private

  def resource
    nil
  end

  def render_api_key(payload: nil)
    render :json, json: {
      api_key: Rails.application.credentials.google_maps_api_key,
      payload: payload,
    }.compact
  end

  def map_for_villa(villa)
    PageView.track!(Date.current, "map/villa/#{villa.id}")
    render_api_key
  end

  def map_for_overview
    PageView.track!(Date.current, "map/static")

    collection = with_current_domain(Villa).active.includes(:route).joins(:geocoding).map { |v|
      VillaTeaserDecorator.new(current_currency, v).as_json.merge(
        lat: v.geocode.latitude,
        lng: v.geocode.longitude,
      )
    }

    render_api_key payload: {
      villas: collection,
      labels: VillaTeaserDecorator.labels,
    }
  end
end
