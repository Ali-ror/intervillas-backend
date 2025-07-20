class VillaSearchesController < ApplicationController
  helper_method :collection

  def index
  end

  def create # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    rooms, beds = Villa.minmax_beds_and_rooms_count.values_at(:rooms, :beds)
    n_rooms     = (params[:rooms].to_i || 1).clamp(*rooms)
    n_people    = (params[:people].to_i || 2).clamp(*beds)

    start_date  = Date.parse(params[:start_date]) rescue Date.current
    min_nights  = VillaInquiry.minimum_booking_nights(start_date)
    end_date    = Date.parse(params[:end_date]) rescue start_date + min_nights
    end_date    = [start_date + min_nights, end_date].max

    # sort dates
    params[:start_date], params[:end_date] = [start_date, end_date].minmax

    villas = collection.select { |v| v.bedrooms_count >= n_rooms && v.beds_count >= n_people }.map { |v|
      main_image = v.images.active.first
      data = {
        id:               v.id,
        name:             v.name,
        locality:         v.locality.presence,
        price_from:       view_context.display_price(v.teaser_price),
        search_url:       villa_path(v, **view_context.search_criteria_period),
        mainimage:   media_url(main_image, preset: :teaser),
        thumbnail_url:    thumbnail_url(v.images.active.first),
        bedrooms:         t("villas.tile.bedrooms", count: v.bedrooms_count),
        beds_count:       v.beds_count,
        minimum_people:   v.minimum_people,
        bathrooms:        t("villas.tile.bathrooms", count: v.bathrooms_count),
        living_area:      t("villas.tile.living_area", area: view_context.living_area(v)),
        pool_orientation: t(v.pool_orientation, scope: "villas.tile.pool_orientation"),
        weekly_pricing:   v.villa_price.weekly_pricing?,
      }

      if v.show_reviews?
        data[:rating] = {
          stars: v.stars,
          count: v.number_of_ratings,
        }
      end

      data
    }

    render json: {
      villas: villas,
      labels: {
        price_from:      t("villas.tile.price_from"),
        price_time_unit: t("villas.tile.price_time_unit"),
      },
    }
  end

  private

  def collection
    with_current_domain(Villa)
      .active
      .includes(:route)
      .search(params[:start_date], params[:end_date], params[:people], params[:rooms])
      .order(Arel.sql("RANDOM()"))
  end

  def thumbnail_url(image)
    if image.attachment_present?
      media_url image, preset: :teaser
    else
      view_context.image_path "logo.png"
    end
  end
end
