import { translate } from "@digineo/vue-translate"

export const COUNTRIES = translate("countries")
export const STATES = translate("state_names")

export function CountryCodeOptions() {
  const prioCC = new Set(["DE", "CH", "AT", "CA", "US"])
  const prio = [],
        rest = []

  Object.entries(COUNTRIES).forEach(([code, name]) => {
    if (prioCC.has(code)) {
      prio.push({ code, name })
    } else {
      rest.push({ code, name })
    }
  })

  prio.sort((a, b) => a.name.localeCompare(b.name))
  rest.sort((a, b) => a.name.localeCompare(b.name))

  return { prio, rest }
}

export function StateOptions(countryCode) {
  const list = STATES[countryCode]
  if (!list) {
    return { label: translate("villa_booking.customer_form.state_code"), type: null }
  }
  if (list === true) {
    return { label: translate("villa_booking.customer_form.state_code"), type: "text" }
  }

  const { label, ...rest } = list
  const states = Object.entries(rest)
    .map(([code, name]) => ({ code, name }))
    .sort((a, b) => a.name.localeCompare(b.name))
  return { label, type: "select", states }
}
