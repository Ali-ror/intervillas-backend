json.extract! boat,
  :id,
  :model,
  :horse_power,
  :url,
  :minimum_days

json.description simple_format(boat.description)

json.prices do
  json.training display_price(boat.training)
  json.deposit display_price(boat.deposit)
end

json.gallery image_gallery_slides(boat.images.active, thumbnail: false)

json.partial! "boats/daily_prices", boat: boat
