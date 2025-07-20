class SpecialsController < InheritedResources::Base
  actions :index

  def index
    specials = end_of_association_chain
    
    render json: specials.map {|special| {
      id: special.id,
      description: special.description,
      start_date: special.start_date,
      end_date: special.end_date,
      percent: special.percent,
      villas: special.villas.map {|villa| serialize_villa(villa)}
    }}
  end

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
      bedrooms: "#{villa.bedrooms_count} Schlaf-zimmer",
      bathrooms: "#{villa.bathrooms_count} Bade-zimmer",
      mainimage: media_url(villa.main_image, preset: :teaser),
      living_area: "#{villa.living_area} m² Fläche",
      medias: villa.images,
      teaser_price: special_price,
      price_from: "$#{special_price}",
      prices: villa.villa_price,
      pool_orientation: pool_orientation_label(villa.pool_orientation),
      created_at: villa.created_at,
      updated_at: villa.updated_at
    }
  end

  def pool_orientation_label(code)
    {
      "n" => "Pool North",
      "s" => "Pool South",
      "e" => "Pool East",
      "w" => "Pool West",
      "ne" => "Pool Northeast",
      "nw" => "Pool Northwest",
      "se" => "Pool Southeast",
      "sw" => "Pool Southwest"
    }[code.downcase] || "Pool"
  end

  protected

  def end_of_association_chain
    super.includes(villas: [:route, tags: [:category]])
      .references(:villas)
      .where("specials.end_date >= ?", Date.current)
  end
end
