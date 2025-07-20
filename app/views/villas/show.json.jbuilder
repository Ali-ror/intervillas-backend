json.id          villa.id
json.name        villa.name
json.active      villa.active
json.slug        villa.to_param

json.teaser      villa.descriptions.get(:teaser)
json.description villa.descriptions.get(:description)
json.header      villa.descriptions.get(:header)

json.tags villa.tags do |tag|
  json.tag do
    json.name     tag.name
    json.category tag.category&.name
  end
end

if villa.geocode.present?
  json.geocode do
    json.latitude  villa.geocode.latitude
    json.longitude villa.geocode.longitude
  end
end

json.highlights do
  json.build_year villa.build_year
  json.last_renovation villa.last_renovation
  json.living_area villa.living_area
  json.pool_orientation do
    json.code villa.pool_orientation
    json.name t(villa.pool_orientation, scope: "villas.cardinal_directions") if villa.pool_orientation.present?
  end
  json.bedrooms_count villa.bedrooms_count
  json.beds_count villa.beds_count
  json.bathrooms_count villa.bathrooms_count
  json.wcs_count villa.wcs_count
  json.tags villa.tags_of_category("highlights").map(&:name)
end

if villa.has_videos?
  json.videos villa.videos.active.joins(preview_attachment: :blob).map { |v|
      {
        name:    v.description.presence || v.de_description.presence || "Video",
        url:     v.video_url,
        preview: media_url(v, preset: :full),
      }
    }
end

if villa.bedrooms.present?
  json.bedrooms villa.bedrooms do |bedroom|
    json.id bedroom.id
    json.tags bedroom.tags.map { |tag| tag.to_s(bedroom.amount_of_tag(tag)) } # e.g., "2x King Bed"
  end

  if (desc = villa.descriptions.get(:bedrooms).presence)
    json.bedroom_description RenderKramdown.new(desc).to_html
  end
end

if villa.bathrooms.present?
  json.bathrooms villa.bathrooms do |bathroom|
    json.id bathroom.id
    json.tags bathroom.tags.map(&:name)
  end

  if (desc = villa.descriptions.get(:bathrooms).presence)
    json.bathroom_description RenderKramdown.new(desc).to_html
  end
end

if villa.boats.present?
  json.boats villa.boats.map {|boat| 
      {
        id:boat.id,
        model: boat.model,
        name: boat.boat_name_builder,
        teaser_price: boat.teaser_price,
        horse_power: boat.horse_power,
        main_image_url: boat.main_image,
        images: boat.images.map {|img| {
          url: media_url(img, preset: :teaser)
        }
      }}
  }
end

if defined?(other_villas) && other_villas.present?
  json.other_villas other_villas.map { |villa| VillaTeaserDecorator.new(current_currency, villa).as_json }
end

json.images villa.images.map {|img| {
          url: media_url(img, preset: :teaser)
        }}

json.price_from  display_price(villa.teaser_price)

json.prices do
  json.weekly_pricing villa_price.weekly_pricing?
  json.base_rate display_price(villa_price.base_rate)

  if villa_price.weekly_pricing?
    json.weekly_price display_price(villa_price.base_rate * 7)
    json.additional_night display_price(villa_price.base_rate)
  else
    json.base_price display_price(villa_price.base_rate)
    json.additional_person display_price(villa_price.additional_adult)

    if villa_price.traveler_price_categories.include?("children_under_6")
      json.children_under_6 display_price(villa_price.children_under_6)
    end

    if villa_price.traveler_price_categories.include?("children_under_12")
      json.children_under_12 display_price(villa_price.children_under_12)
    end
  end

  json.incl_taxes I18n.t("villas.show.incl_taxes_2019") # ← ✅ Add tax line as translation

  json.holiday_discounts villa.holiday_discounts.map { |discount|
    {
      label: I18n.t("discount.name_amount", discount: I18n.t(discount.description, scope: :discount), percent: discount.percent),
      range: I18n.t("discount.range", days_before: discount.days_before, days_after: discount.days_after)
    }
  }

  hs_scope = villa.high_seasons.after(Date.current)
  min = hs_scope.minimum(:addition).presence
  max = hs_scope.maximum(:addition).presence

  if min && max
    json.high_season_discount do
      json.label I18n.t("discount.name_amount", discount: I18n.t("villas.show.high_season"), percent: [min, max].uniq.join("-"))
      json.range I18n.t("discount.high_season_range")
    end
  end
end

