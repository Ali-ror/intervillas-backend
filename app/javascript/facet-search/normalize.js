export const normalizeVilla = (villa, labels) => {
  Object.assign(villa, {
    labels,
    priceFrom:       villa.price_from,
    searchUrl:       villa.search_url,
    thumbnailUrl:    villa.thumbnail_url,
    livingArea:      villa.living_area,
    poolOrientation: villa.pool_orientation,
    weeklyPricing:   villa.weekly_pricing,
    bedsCount:       villa.beds_count,
    minimumPeople:   villa.minimum_people,
  })

  delete villa.price_from
  delete villa.search_url
  delete villa.thumbnail_url
  delete villa.living_area
  delete villa.pool_orientation
  delete villa.weekly_pricing
  delete villa.beds_count

  return villa
}
