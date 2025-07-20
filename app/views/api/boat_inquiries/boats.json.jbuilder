json.array! available_boats do |boat|
  json.extract! boat, :id, :model

  if (img = boat.images.active.first)
    json.thumbnails image_srcset(img, preset: :teaser)
  end

  if boat.inclusive?
    json.note t("boats.boat.inclusive")
  else
    days, price = boat.teaser_price
    json.note [
      t("boats.boat.ab"),
      display_price(price),
      t("boats.boat.bei_buchung_von_x_tagen", x: days),
    ].join(" ")
  end

  occupancies = OccupancyExporter.from(boat)
  json.occupancies occupancies.public_export(limit: [start_date, end_date])
end
