json.villas villas do |v|
  eur = v.villa_price_eur&.traveler_price_categories
  usd = v.villa_price_usd&.traveler_price_categories

  next if !eur && !usd && villa_inquiry.villa_id != v.id

  json.call v,
    :id,
    :minimum_people,
    :energy_cost_calculation
  json.name v.admin_display_name

  json.traveler_price_categories do
    json.eur eur if eur
    json.usd usd if usd
  end

  json.currencies [("EUR" if eur), ("USD" if eur || usd)].compact
end
