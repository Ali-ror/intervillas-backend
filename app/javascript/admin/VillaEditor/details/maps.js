function sanitize(s) {
  return encodeURIComponent(s).replace(/%20/g, "+").replace(/%2C/gi, ",")
}

export function gmapsLink({ street, locality, postal_code, region, country, latitude, longitude }) {
  const addr = sanitize([street, locality, postal_code, region, country].join(", "))
  return `https://www.google.de/maps/place/${addr}/@${latitude},${longitude},17z`
}
