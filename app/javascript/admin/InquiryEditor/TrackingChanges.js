import { format, isAfter, isBefore, isValid } from "date-fns"
import { makeDate } from "../../lib/DateFormatter"

// TrackingChanges is used to display UI hints when certain inquiry fields
// have changed. Currently, the fields in question are:
//
// - for villa_inquiry: villa_id, start_date, end_date, and
// - for boat_inquiry: boat_id, start_date, end_date.
//
// Changes in villa/boat ID will trigger a cancellation for the old and
// a confirmation for the new villa/boat, while changes in start/end
// dates will trigger update notifications.
class TrackingChanges {
  constructor() {
    this.reset()
  }

  track({ villa_inquiry, boat_inquiry } = {}) {
    if (villa_inquiry) {
      this.villa.id = this._toId(villa_inquiry.villa_id)
      const { startDate, endDate } = this._villaDates(villa_inquiry)
      this.villa.startDate = startDate
      this.villa.endDate = endDate
    }
    if (boat_inquiry) {
      this.boat.id = this._toId(boat_inquiry.boat_id)
      const { startDate, endDate } = this._boatDates(boat_inquiry)
      this.boat.startDate = startDate
      this.boat.endDate = endDate
    }
  }

  changes({ villa_inquiry, boat_inquiry } = {}) {
    const changes = {
      villa: null,
      boat:  null,
    }

    if (villa_inquiry) {
      // if ID has changed, start/end dates are irrelevant
      const id = this._toId(villa_inquiry.villa_id)
      if (this.villa.id !== id) {
        if (!this.villa.id && id) {
          changes.villa = "added"
        } else {
          changes.villa = "id"
        }
      } else {
        const { startDate, endDate } = this._villaDates(villa_inquiry)
        if (this.villa.startDate !== startDate || this.villa.endDate !== endDate) {
          changes.villa = "dates"
        }
      }
    }
    if (boat_inquiry) {
      // if ID has changed or boat was removed, start/end dates are irrelevant
      // TODO: conditional seem a bit convoluted.
      const id = this._toId(boat_inquiry.boat_id)
      if (this.boat.id !== id && !boat_inquiry._destroy) {
        if (!this.boat.id && id) {
          changes.boat = "added"
        } else {
          changes.boat = "id"
        }
      } else if (this.boat.id && boat_inquiry._destroy) {
        changes.boat = "removed"
      } else if (this.boat.id && id) {
        const { startDate, endDate } = this._boatDates(boat_inquiry)
        if (this.boat.startDate !== startDate || this.boat.endDate !== endDate) {
          changes.boat = "dates"
        }
      }
    }
    return changes
  }

  reset() {
    this.villa = { id: null, startDate: null, endDate: null }
    this.boat = { id: null, startDate: null, endDate: null }
  }

  /** @private Normalizes record IDs */
  _toId(val) {
    const id = parseInt(val, 10) // null, undefined, "garbage" => NaN
    return Number.isNaN(id) ? null : id
  }

  /** @private Extracts min/max dates from VillaInquiry and its travelers */
  _villaDates({ start_date, end_date, travelers }) {
    if (!travelers.length) {
      // start/end date of villa inquiry is only relevant when there are no travelers
      const s = makeDate(start_date),
            e = makeDate(end_date)
      return {
        startDate: isValid(s) ? format(s, "yyyy-MM-dd") : null,
        endDate:   isValid(e) ? format(e, "yyyy-MM-dd") : null,
      }
    }

    // otherwise find min/max start/end dates in travelers
    const { min, max } = travelers.reduce((dates, t) => {
      const s = makeDate(t.start_date),
            e = makeDate(t.end_date)
      if (isBefore(s, dates.min)) {
        dates.min = s
      }
      if (isAfter(e, dates.max)) {
        dates.max = e
      }
      return dates
    }, {
      min: makeDate(travelers[0].start_date),
      max: makeDate(travelers[0].end_date),
    })

    return {
      startDate: format(min, "yyyy-MM-dd"),
      endDate:   format(max, "yyyy-MM-dd"),
    }
  }

  /** @private Extracts min/max dates from BoatInquiry */
  _boatDates(boat_inquiry) {
    const s = makeDate(boat_inquiry.start_date),
          e = makeDate(boat_inquiry.end_date)
    return {
      startDate: format(s, "yyyy-MM-dd"),
      endDate:   format(e, "yyyy-MM-dd"),
    }
  }
}

export default {
  data() {
    return {
      // If this.inquiry changes in some fields, we'll automatically send a note
      // mail to the owners and managers. We also want to display a hint in the UI,
      // and for that we'll need to track the changes here as well.
      //
      // Values are set in this._updateDataFromRemote (see ./Common.js)
      trackingChanges: new TrackingChanges(),
    }
  },

  computed: {
    changes() {
      return this.trackingChanges.changes(this.inquiry)
    },
  },
}
