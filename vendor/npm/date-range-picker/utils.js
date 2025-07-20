import {
  addDays, addMonths,
  differenceInHours,
  format,
  getDefaultOptions,
  isDate, isValid,
  min, max,
  parseISO,
} from "date-fns"
import { DateRange } from "./DateRange"

/**
 * Normalisiert eine Eingabe zu einer Zeit. Die Uhrzeit wird auf 12 Uhr
 * (oder hour, wenn übergeben) gesetzt.
 * @param {Date | string | number} input
 *    Etwas, aus dem sich eine neue Date-Instanz bilden lässt.
 *    String-Werte müssen sich ans ISO-Format halten
 * @param {number | false} [hour=12]
 *    Tageszeit (0..23, default 12) zur Normalisierung, oder `false`, um die Normalisierung
 *    zu überspringen.
 * @returns {Date}
 */
export function ensureDate(input, hour = 12) {
  if (!input) {
    throw new Error(`expected argument to be, got "${input}" (${typeof input})`)
  }
  if (isDate(input) && !isValid(input)) {
    throw new Error("got invalid date")
  }
  if (hour !== false && (hour < 0 || hour > 23)) {
    throw new RangeError(`hour out of range: ${hour} must be >= 0 and <= 23`)
  }

  const date = makeDate(input)
  if (hour !== false) {
    date.setHours(hour, 0, 0, 0)
  }
  return date
}

/**
 * Versucht `input` in ein `Date` zu konvertieren.
 *
 * Funktion ist primär für den internen Gebrauch gedacht und erwartet, dass der Caller
 * sowohl Parametervalidierung und Fehlerbehandlung übernimmt.
 *
 * @param {Date | number | string} input
 * @returns {Date}
 */
export function makeDate(input) {
  return isDate(input) || Number.isFinite(input)
    ? new Date(input)
    : parseISO(input)
}

/**
 * Formatiert ein Datum. Die Locale muss in der Host-Anwendung via date-fns'
 * `setDefaultOptions({ locale: x })` gesetzt werden. Ohne Anpassung wird das
 * US-amerikanische Format verwendet.
 *
 * @param {Date | number} date Das zu formatierende Datum.
 * @returns {string} Das formatierte Datum.
 */
export function fmt(date) {
  return format(ensureDate(date), "P")
}

/**
 * @param  {...(Date | number)} dates List of dates
 * @returns {[min: Date, max: Date]} min and max date from the given list
 */
const dateLimits = (...dates) => [min(dates), max(dates)]

/**
 * Erzeugt eine DateRange von min(a,b)..max(a,b)
 * @param {Date | number} a
 * @param {Date | number} b
 * @returns {DateRange}
 */
export function orderedRange(a, b) {
  const [start, end] = dateLimits(a, b)
  return new DateRange(start, end)
}

/**
 * Berechnet die absolute Differenz zwischen zwei Daten, in exakten
 * 24h-Intervallen und ohne Berücksichtigung von Zeitumstellungen.
 *
 * @param {Date | number} a
 * @param {Date | number} b
 */
export function absDiffDays(a, b) {
  const [start, end] = dateLimits(a, b)
  return Math.abs(Math.floor(differenceInHours(start, end) / 24) | 0)
}

/**
 * Kapselt Logik zum Füllen von <input>-Tags für Start-/End-Datum
 *
 * @param {string} name Name für das Input-Tag
 * @param {string} [fmt="yyyy-MM-dd"] date-fns-kompatible Format-Anweisung
 * @param {Date | number} [value] Zu formatierende Zeit
 * @returns {{ name: string, value: string | undefined }}
 */
export function DateInput(name, fmt = "yyyy-MM-dd", value = null) {
  return {
    name:  name,
    value: value && format(value, fmt),
  }
}

class LocalData {
  /** @param {string} locale  */
  constructor(locale) {
    this.locale = locale

    this._pivot = new Date(2023, 0, 1, 12, 0, 0, 0) // 2023-01-01 was Sunday
    this._formats = ["long", "short"]

    /** @type {{ dow: number, long: string, short: string }} */
    this._daysOfWeek = null

    /** @type {{ long: string, short: string }[]} */
    this._monthNames = null
  }

  /** Returns list of week days names, with the first day of the week at position 0. */
  get daysOfWeek() {
    if (!this._daysOfWeek) {
      const offset = getDefaultOptions().weekStartsOn || 0, // 0 = Sun
            startOfWeek = addDays(this._pivot, offset) // shift pivot date to start of week

      this._daysOfWeek = this._collect(7, startOfWeek, addDays, "weekday").map((d, i) => ({
        dow: (i + offset) % 7,
        ...d,
      }))
    }
    return this._daysOfWeek
  }

  /** Returns list of month names. */
  get monthNames() {
    if (!this._monthNames) {
      this._monthNames = this._collect(12, this._pivot, addMonths, "month")
    }
    return this._monthNames
  }

  /**
   * @private Internal helper to build up data.
   * @param {number} n
   * @param {Date} date
   * @param {addDays | addMonths} adder
   * @param {"weekday" | "month"} intl Name of DateTimeFormat output option
   * @returns {typeof (this._daysOfWeek | this._monthNames)}
   */
  _collect(n, date, adder, intl) {
    const formats = this._formats.map(name => ({
      name,
      format: new Intl.DateTimeFormat(this.locale, { [intl]: name }).format,
    }))

    return [...Array(n)].map((_, index) => {
      const curr = adder(date, index)
      return formats.reduce((list, l10n) => {
        list[l10n.name] = l10n.format(curr)
        return list
      }, {})
    })
  }
}

/** @type {Map<string, LocaleData>} Keyed by BCP 47 language tag */
const localeData = new Map()

/**
 * Extracts weekday and month names from `Intl.DateTimeFormat` for a given
 * `locale`. When unspecified, the locale is extracted from `document.body.lang`.
 * A missing or invalid locale causes this function to return `undefined`.
 * Additionally, invalid locales will log an error message.
 *
 * @param {string} [locale=document.body.lang] A BCP 47 language tag.
 * @returns {LocaleData | undefined}
 */
export function getLocaleData(locale = document.body.lang) {
  if (!locale) {
    return undefined
  }
  if (!localeData.has(locale)) {
    try {
      localeData.set(locale, new LocalData(locale))
    } catch (err) {
      console.error("failed to construct LocaleData", { locale }, err)
      localeData.set(locale, undefined)
    }
  }
  return localeData.get(locale)
}
