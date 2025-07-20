class VillasController < ApplicationController
  include PriceHelper
  helper_method :new_villa_inquiry_path, :resource

  expose :villas do
    with_current_domain(Villa)
      .active
      .includes(:route)
      .order(Arel.sql("RANDOM()"))
  end

  expose :villa do
    with_current_domain(Villa).includes({
      bedrooms:  { tags: :category },
      bathrooms: { tags: :category },
      tags:      :category,
    }).find params[:id]
  end
  alias resource villa

  expose(:other_villas) { with_current_domain(Villa.random(3)).includes(:route, { tags: :category }) }
  expose(:boats)        { villa.boats }

  delegate :villa_price, to: :villa
  private :villa_price
  helper_method :villa_price

  def unavailable_dates
    dates = Villa.unavailable_dates

    respond_to do |format|
      format.json { render json: dates }
      format.html { render plain: "This endpoint only supports JSON", status: :not_found }
    end
  end

  def index
    if params[:start_date] && params[:end_date]
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      people = params[:people].to_i > 0 ? params[:people].to_i : 2
      rooms = params[:rooms].to_i > 0 ? params[:rooms].to_i : 1

      @villas = with_current_domain(Villa).search(start_date, end_date, people, rooms)
                  .includes(:route, :bedrooms, :bathrooms)
    else
      @villas = villas.includes(:bedrooms, :bathrooms)
    end

    render json: @villas.map { |villa| VillaTeaserDecorator.new(current_currency, villa).as_json }
  end

  private

  def serialize_villa(villa)
    special = villa.current_special
    special_price = nil
    if special.present?
      regular_price = villa.villa_price.calculate_base_rate(
        occupancy: villa.minimum_people,
        category: :adults
      ) * 7
      percent = special.percent # Assuming this field holds the discount percent
      discounted_price = regular_price - (regular_price * percent / 100)
      special_price = (discounted_price * 100).round / 100.0
    end

    {
      id: villa.id,
      name: villa.name,
      locality: villa.locality,
      region: villa.region,
      country: villa.country,
      street: villa.street,
      postal_code: villa.postal_code,
      bedrooms_count: villa.bedrooms_count,
      bathrooms_count: villa.bathrooms_count,
      living_area: villa.living_area,
      medias: villa.images,
      teaser_price: villa.teaser_price,
      special_price: special_price,
      thumbnail_url: villa.thumbnail_url,
      prices: villa.villa_price,
      pool_orientation: villa.pool_orientation,
      created_at: villa.created_at,
      updated_at: villa.updated_at
    }
  end

  def show
    if villa.active && villa.to_param != params[:id]
      redirect_to villa_url(villa), status: :moved_permanently
      return
    end

    respond_to do |format|
      format.html { render "show", status: villa.active ? :ok : :gone }
      format.json
    end
  end

  def gallery
    if villa.active
      redirect_to villa_url(villa), status: :moved_permanently
      return
    end

    @title = villa.name
    render "show", status: villa.active ? :ok : :gone
  end

  def redirect_unlocalized
    if params[:id].blank?
      redirect_to villas_url, status: :moved_permanently
    else
      redirect_to villa_url(villa), status: :moved_permanently
    end
  end

  private

  def new_villa_inquiry_path(*attr)
    new_villa_villa_inquiry_path(*attr)
  end
end
