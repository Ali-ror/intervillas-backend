import { translate } from "@digineo/vue-translate"
import { parseISO, format, toDate } from "date-fns"

const dataTimeFormat = document.body.getAttribute("lang") === "de"
  ? "P, p 'Uhr'"
  : "P, p"

export const makeDate = input => {
  const type = Object.prototype.toString.call(input)
  if (input instanceof Date || (typeof input === "object" && type === "[object Date]")) {
    return input
  }
  if (typeof input === "string" || (typeof input === "object" && type === "[object String]")) {
    return parseISO(input)
  }
  return toDate(input)
}

export function formatDateTime(input) {
  return format(makeDate(input), dataTimeFormat)
}

export function formatDate(input) {
  return format(makeDate(input), "P")
}

export function formatDateRange({ start_date, end_date }) {
  return translate("shared.discount.range", {
    start: formatDate(start_date),
    end:   formatDate(end_date),
  })
}
