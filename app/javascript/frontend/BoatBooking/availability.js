import { translate } from "@digineo/vue-translate"
import { DateRange } from "@digineo/date-range-picker"
import { addDays, eachDayOfInterval, setHours } from "date-fns"
import { makeDate } from "../../lib/DateFormatter"

export function annotateAvailability(boats, { arrival, departure }) {
  const maxBoatRange = new DateRange(
    setHours(addDays(arrival, 1), 8),
    setHours(addDays(departure, -1), 16),
  )

  return boats.map(boat => withAvailability(boat, maxBoatRange))
}

function withAvailability(boat, maxBoatRange) {
  const occupancies = boat.occupancies.map(o => new DateRange(makeDate(o[0]), makeDate(o[1])))

  const availableDays = eachDayOfInterval(maxBoatRange),
        fullyAvailable = availableDays.length

  for (let i = 0, len = occupancies.length; i < len; ++i) {
    const occ = occupancies[i]
    for (let j = availableDays.length - 1; j >= 0; --j) {
      if (occ.contains(availableDays[j])) {
        availableDays.splice(j, 1)
      }
    }
  }

  const key = (() => {
    switch (availableDays.length) {
    case fullyAvailable: return "full"
    case 0: return "none"
    default: return "limited"
    }
  })()

  return {
    ...boat,
    availability: {
      key,
      title: translate(`boat_booking.availability.${key}.title`),
      desc:  translate(`boat_booking.availability.${key}.desc`),
    },
  }
}
