import { endOfDay, parse, setHours, startOfDay } from "date-fns"
import Utils from "./utils"
import { DateRange } from "@digineo/date-range-picker"

//
// Ein "Provider" ist eine Objekt, dass via einer (kontext-spezifischen) get-Methode eine Liste von
// Daten oder Zeiträumen liefert. Die Argumente definieren hier den Kontext: Für Weihnachten ist nur
// das Jahr relevant, für eine Hochsaison ist ggf. die Villa notwendig.
//

/**
 * Ein naiver In-Memory-Key-Value-Store
 */
class Cache {
  constructor() {
    this.cache = {}
  }

  retrieveOrStore(key, setter) {
    if (!Object.prototype.hasOwnProperty.call(this.cache, key)) {
      this.cache[key] = setter()
    }
    return this.cache[key]
  }
}

const buildRange = (start, end) => {
  const s = startOfDay(start),
        e = endOfDay(end)
  return new DateRange(s, e)
}

/**
 * Liefert für ein bestimmtes Jahr eine DateRange die über die Weihnachtsfeiertage
 * geht. Mit NightsCalculator#minimum_booking_nights synchron halten!
 */
class XmasProvider {
  constructor() {
    this.cache = new Cache()
  }

  setup() {
    return Promise.resolve()
  }

  get(year) {
    return this.cache.retrieveOrStore(year, () =>
      buildRange(new Date(year, 11, 23), new Date(year, 11, 26)),
    )
  }
}

/**
 * Die API-Provider liefern eine Liste Datumsgrenzen (SpecialDates.highSeasonProvider), die sich aus
 * einer JSON-API füttern.
 *
 * Damit dies bequem zu nutzen ist, kommen Promises zum Einsatz, mit dem der Kontrollfluss
 * gesteuert werden kann:
 *
 *   var p = SpecialDates.highSeasonProvider.setup(api1_url)
 *
 *   p.then(function(){
 *     // API-Provider sind ist nun fertig
 *   }, function(err) {
 *     // AJAX ist fehlgeschlagen, oder setup wurde an anderer Stelle mit anderer URL ausgeführt,
 *     // in diesem Fall ist err.name == "ReSetupError"
 *   })
 *
 * Mehrfaches Ausführen der setup-Funktionen (mit derselben URL) gibt dasselbe Promise zurück, und
 * das Promise geht sofort in den resolved-Zustand über. Bei verschiedenen URLs wird das alte Promise
 * sofort verworfen.
 */
class APIProvider {
  constructor() {
    this.cache = new Cache()
    this._promise = null // Promise
    this._reject = null // Promise rejector
    this.url = null // last successful URL given to setup
    this.data = [] // last successful response data
  }

  setup(url) {
    // same URL?
    if (this._promise !== null && url === this.url) {
      return this._promise
    }
    // reject currently active promise
    if (typeof this._reject === "function") {
      const err = new Error("rejected after re-setup")
      err.name = "ReSetupError"
      this._reject(err)
    }

    // get JSON from server
    this._promise = new Promise((resolve, reject) => {
      this._reject = reject // remember reject function

      Utils.fetchJSON(url)
        .then(data => resolve(data))
        .catch(err => reject(err))
    }).then(data => {
      this._reject = null // make it uncallable
      this.url = url
      this._setData(data)
    })
    return this._promise
  }

  get(...args) {
    return this.cache.retrieveOrStore(args, () => this._find(...args))
  }
}

class HighSeasonProvider extends APIProvider {
  /** @private */
  _setData(data) {
    const am = setHours(new Date(), 8),
          pm = setHours(new Date(), 16)

    this.data = data.map(season => {
      return {
        range: buildRange(
          parse(season.starts_on, "yyyy-MM-dd", pm),
          parse(season.ends_on, "yyyy-MM-dd", am),
        ),
        villas: season.villa_ids,
      }
    })
  }

  /** @private */
  _find(year, villaID) {
    const ref = new DateRange(
      new Date(year, 0, 1),
      new Date(year, 11, 31, 23, 59, 59, 999),
    )

    return this.data.reduce((list, { range, villas }) => {
      if (ref.overlaps(range)) {
        // range ist relevant
        if (!villaID || villas.includes(+villaID)) {
          // entweder ist villa_id undefined, oder wir haben einen Treffer
          return list.concat(range)
        }
      }
      return list
    }, [])
  }
}

const SpecialDates = {
  xmas:       new XmasProvider(),
  highSeason: new HighSeasonProvider(),
}

/**
 * Berechnet die Mindestbuchungsdauer für ein Datum.
 * @param {Date} date Anreisedatum
 * @return Number
 */
export function rangeSize(date, min = 7) {
  const xmas = SpecialDates.xmas.get(date.getFullYear())
  return xmas.contains(date) ? Math.max(14, min) : min
}

/**
 * (Vue-Helper) Berechnet Annotationen für ein Datum.
 * @param {Date} date
 * @return Object
 */
export function annotate(date) {
  const seasons = SpecialDates.highSeason.get(date.getFullYear())
  for (let i = 0, len = seasons.length; i < len; ++i) {
    if (seasons[i].contains(date)) {
      return { "high-season": true }
    }
  }
  return {}
}

let setupPromise

/**
 * Holt die Default-Daten vom Server.
 * @return Promise
 */
export function awaitSpecialDates() {
  if (!setupPromise) {
    setupPromise = Promise.all([
      SpecialDates.xmas.setup(),
      SpecialDates.highSeason.setup("/api/high_seasons.json"),
    ])
  }
  return setupPromise
}

export default SpecialDates
