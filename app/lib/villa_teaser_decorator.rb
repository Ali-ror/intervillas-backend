class VillaTeaserDecorator < SimpleDelegator
  include Rails.application.routes.url_helpers
  include LocalizedRoutes::Helper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::AssetUrlHelper
  include PriceHelper
  include VillasHelper
  include MediaHelper

  def self.wrap_all(currency, villas)
    {
      villas: villas.map { |villa| new(currency, villa) },
      labels: labels,
    }
  end

  def self.wrap(currency, villa)
    {
      villa:  new(currency, villa, minimal: true),
      labels: labels,
    }
  end

  def self.labels
    {
      price_from:      I18n.t("villas.tile.price_from"),
      price_time_unit: I18n.t("villas.tile.price_time_unit"),
    }
  end

  attr_reader :current_currency

  def initialize(currency, villa, minimal: false)
    @current_currency = currency
    @minimal          = minimal
    super(villa)
  end

  def path
    villa_path(__getobj__)
  end

  def thumbnail_path(medium)
    if medium&.attachment_present?
      media_url medium, preset: :teaser
    else
      image_path "logo.png"
    end
  end

  def main_image_url
    if respond_to?(:main_image) && main_image&.attachment_present?
      media_url(main_image, preset: :teaser)
    elsif images.any?
      media_url(images.active.first, preset: :teaser)
    else
      image_path("logo.png")
    end
  end

  def as_json(*)
    data = {
      price_from:             display_price(teaser_price),
      beds_count:             beds_count,
      weekly_pricing:         villa_price&.weekly_pricing? || false,
      currencies:             Set.new(available_currencies),
      minimum_booking_nights: minimum_booking_nights,
      minimum_people:         minimum_people,
    }

    # XXX: Hmm... Villas with EUR-prices are auto-convertible to USD, but
    # #available_currencies doesn't report USD.
    data[:currencies] << Currency::USD if data[:currencies].include?(Currency::EUR)

    @minimal ? data : with_extra_data(data)
  end

  def with_extra_data(data)
    data.merge(
      id:               id,
      name:             name,
      locality:         locality.presence,
      search_url:       path,
      mainimage:        main_image_url,
      thumbnail_url:    thumbnail_path(images.active.first),
      bedrooms:         I18n.t("villas.tile.bedrooms", count: bedrooms_count),
      bathrooms:        I18n.t("villas.tile.bathrooms", count: bathrooms_count),
      living_area:      I18n.t("villas.tile.living_area", area: living_area(__getobj__)),
      pool_orientation: I18n.t(pool_orientation, scope: "villas.tile.pool_orientation"),
      rating:           ({ stars: stars } if show_reviews?),
    )
  end
end
