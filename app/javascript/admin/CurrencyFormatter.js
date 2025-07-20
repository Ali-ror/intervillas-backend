import { has } from "../lib/has"

/** @type {Record<string, Intl.NumberFormat>} */
const FORMATTERS = {}

export function currency(val, currency = "EUR") {
  if (val.value) {
    currency = val.currency
    val = val.value
  }
  if (!has(FORMATTERS, currency)) {
    FORMATTERS[currency] = new Intl.NumberFormat("de", {
      style:           "currency",
      currency,
      currencyDisplay: "symbol",
    })
  }
  return FORMATTERS[currency].format(+val)
}

export default {
  filters: {
    currency,
  },
}
