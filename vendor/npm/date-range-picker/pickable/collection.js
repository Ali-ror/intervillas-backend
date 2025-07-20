import {
  addDays,
  differenceInMilliseconds,
  min as minDate,
  max as maxDate,
  isBefore, isAfter,
  startOfDay, endOfDay,
  startOfWeek, endOfWeek,
  startOfMonth, endOfMonth,
  toDate,
} from "date-fns"
import Day from "./day"
import { DateRange } from "../DateRange"
import { absDiffDays, makeDate } from "../utils"

const propKeys = {
  min:   Symbol("min"),
  max:   Symbol("max"),
  first: Symbol("first"),
  last:  Symbol("last"),
}

/**
 * Hilfsfunktion. Prüft, ob zwei Zeitpunkte direkt nebeneinander liegen.
 * Gedacht als Zusatz zu `DateRange#overlaps(other, { adjacent: true })`,
 * was etwas anderes prüft (siehe /spec/sanity.spec.js)
 *
 * @param {Date | number} a Datum
 * @param {Date | number} b Datum
 */
const adjacent = (a, b) => Math.abs(differenceInMilliseconds(a, b)) <= 1

/**
 * Prüft, ob ein Zeitpunkt in einem Zeitfenster oder neben dem Start/Ende
 * des Zeitfensters lieft.
 * @param {DateRange} r
 * @param {Date | number} d
 * @returns {boolean}
 */
const within = (r, d) => r.contains(d) || adjacent(d, r.start) || adjacent(d, r.end)

/**
 * @param {DateRange[]} list blockierte Zeiträume
 * @param {Date | number} [min] minimal gültiger Zeitpunkt
 * @param {Date | number} [max] maximal gültiger Zeitpunkt
 */
function sortAndMerge(list, min, max) {
  // sort days by start date
  let sorted = list.slice(0)
  sorted.sort((a, b) => a.start - b.start)

  // find and merge overlapping ranges
  /** @type {DateRange[]} */
  const stack = []
  for (let i = 0, len = sorted.length; i < len; ++i) {
    const curr = sorted[i],
          prev = stack.pop() // may be undefined!

    // prev.start <= min <= prev.end: drop prev, move min forward
    if (min && prev && within(prev, min)) {
      min = prev.end
      stack.push(curr)
      continue
    }
    // curr.start <= max <= curr.end: drop curr, move max back
    if (max && within(curr, max)) {
      max = curr.start
      if (prev) {
        stack.push(prev)
      }

      continue
    }
    if (prev) {
      if (prev.overlaps(curr)) {
        stack.push(prev.add(curr))
        continue
      }
      if (adjacent(prev.end, curr.start)) {
        stack.push(new DateRange(
          minDate([prev.start, curr.start]),
          maxDate([prev.end, curr.end]),
        ))
        continue
      }

      stack.push(prev, curr)
    } else {
      stack.push(curr)
    }
  }
  return { merged: stack, min, max }
}

/**
 * @typedef {Date | number | string} DateInput Something to construct a Date
 * from. String values must obey ISO formatting.
 */

/**
 * Normalisiert einen Zeitraum zu einem 2-elementigem Array von
 * Date-Instanzen. Als Eingabe werden akzeptiert:
 *
 * - Array mit zwei Datumsrepräsentationen (`normalizeDateRange([a, b])`)
 * - einzelne Datumsrepräsentation (`normalizeDateRange(a)`)
 * - DateRange-Instanzen
 *
 * @param {([DateInput, DateInput] | DateInput | DateRange)} el Eingabe, die in einen Zeitraum überführt werden kann.
 * @returns {[Date, Date]} Array mit Start- und Enddatum eines Zeitraums. Kann leer sein bei ungültigen Eingaben!
 */
function normalizeDateRange(el) {
  if (!el) {
    return [] // ignore empty entries
  }
  if (Array.isArray(el)) {
    if (el.length !== 2) {
      return [] // ignore malformed input
    }

    const a = makeDate(el[0]),
          b = makeDate(el[1])
    // ensure start < eend
    if (isBefore(a, b)) {
      return [a, b]
    }
    return [b, a]
  }
  if (el instanceof DateRange) {
    if (el.start && el.end) {
      // el intanceof DateRange
      return [new Date(el.start), new Date(el.end)]
    }
    // ignore invalidly contructed data
    return []
  }

  // expand to full day
  const a = makeDate(el)
  return [startOfDay(a), endOfDay(a)]
}

/**
 * Transformiert und filtert eine Liste von belegten Zeiträumen, so dass
 * sie zur An/Abreise passen (min und max).
 *
 * @param {any[]} list Liste von Zeiträumen (wird mit normalisiert)
 * @param {Date | number} [min] Anreisedatum
 * @param {Date | number} [max] Abreisedatum
 * @returns {DateRange[]}
 */
function fromUnavailable(list, min, max) {
  if (!Array.isArray(list)) {
    // make it iteratable
    list = [list]
  }

  const result = []

  for (let i = 0, len = list.length; i < len; ++i) {
    let [start, end] = normalizeDateRange(list[i])
    if (!start) {
      continue // ignore
    }
    if (min && isAfter(min, start)) {
      // cap dates before min
      if (isBefore(min, end)) {
        start = min // start < min < end: cap start to min
      } else {
        continue // end < min: ignore range
      }
    }
    if (max && isAfter(end, max)) {
      // cap dates after max
      if (isBefore(max, start)) {
        continue // max < start: ignore
      } else {
        end = max // start < max < end: cap end to max
      }
    }

    result.push(new DateRange(start, end))
  }
  return result
}

/**
 * Eine Collection repräsentiert eine Sammlung aufeinander folgenden Zeiträumen,
 * die entweder "frei" oder "blockiert" sind.
 *
 * Zeitpunkte gelten per Default als frei, und blockierte Zeiträume müssen
 * explizit im Konstruktor angegeben werden.
 *
 * Es gibt folgende Fälle zu berücksichtigen sofern keine blockierten Zeiträume
 * existieren (*min/max* = es gibt ein min-/max-Datum, *Z* = ausgewählter
 * Zeitraum, mit *s/e* = Start-/End-Datum der Auswahl):
 *
 * | min | max | gültige Zeiträume |
 * |:---:|:---:|:------------------|
 * |  T  |  T  | min < Z < max     |
 * |  T  |  F  | min < Z           |
 * |  F  |  T  | Z < max           |
 * |  F  |  F  | alle              |
 *
 * Falls blockierte Zeiträume existieren, darf ein ausgewählter Zeitraum
 * sich nicht mit einem blockierten Zeitraum überdecken. Zusätzlich gelten
 * diese "virtuellen" Zeiträume (*f* = erstes blockiertes Datum,
 * *l* = letztes blockiertes Datum):
 *
 *  - wenn min gegeben
 *    - *(-Infinity..min]* = blockiert
 *    - *(min..f)* = frei
 *  - ansonsten *(-Infinity..f)* = frei
 *  - wenn max gegeben
 *    - *(l..max)* = frei
 *    - *[max..Infinity)* = blockiert
 *  - ansonsten *(l..Infinity)* = frei
 */
export default class Collection {
  /**
   * Konstruiert unter Vorgabe der Randbedingungen eine neue Collection.
   *
   * `unavailableDates` kann eine einzelne Datumsrepräsentation oder ein Array
   * von einzelnenen Datumsrepräsentation, oder ein Array von 2-elementigen Arrays
   * sein, z.B.:
   *
   *    fromUnavailable(x)
   *    fromUnavailable([x,y,z])
   *    fromUnavailable([[xstart,xend],y,z])
   *
   * Einzelne Datumsrepräsentationen werden dabei zu Ranges "aufgeblasen", die
   * den ganzen Tag umfassen (`x` → `startOfDay(x)..endOfDay(x)`).
   *
   * `min` und `max` werden bei der Transformation der `unavailableDates` beachtet.
   * DateRanges, die teilweise vor `min` oder nach `max` liegen werden entsprechend
   * beschnitten, und DateRanges die komplett ausserhalb liegen werden vollständig
   * ignoriert.
   *
   * @param {*} [unavailableDates] Liste von blockierten Datumsbereichen
   * @param {DateInput} [min] minimal gültiger Zeitpunkt, Daten < min werden ignoriert
   * @param {DateInput} [max] maximal gültiger Zeitpunkt, Daten > max werden ignoriert
   */
  constructor(unavailableDates, min, max) {
    min = min ? makeDate(min) : null
    max = max ? makeDate(max) : null
    if (min && max && isAfter(min, max)) {
      throw new RangeError("min > max")
    }

    const filtered = fromUnavailable(unavailableDates, min, max),
          prepared = sortAndMerge(filtered, min, max),
          n = prepared.merged.length

    /** @type {DateRange[]} */
    this.blocked = prepared.merged
    /** @type {Date | number | undefined} */
    this[propKeys.min] = prepared.min
    /** @type {Date | number | undefined} */
    this[propKeys.max] = prepared.max
    /** @type {DateRange | undefined} */
    this[propKeys.first] = n > 0 ? this.blocked[0].start : undefined
    /** @type {DateRange | undefined} */
    this[propKeys.last] = n > 0 ? this.blocked[n - 1].end : undefined
  }

  /**
   * Minmal auswählbares Datum. Alle Zeitpunkte vor diesem Datum gelten
   * als "blockiert", und alle Zeitpunkte zwischen `min` und `first` gelten
   * als "frei".
   */
  get min() {
    const val = this[propKeys.min]
    return val ? toDate(val) : undefined
  }

  /**
   * Minmal auswählbares Datum. Alle Zeitpunkte nach diesem Datum gelten
   * als "blockiert", und alle Zeitpunkte zwischen `last` und `max` gelten
   * als "frei".
   */
  get max() {
    const val = this[propKeys.max]
    return val ? toDate(val) : undefined
  }

  /** Erstes blockiertes Datum. */
  get first() {
    const val = this[propKeys.first]
    return val ? toDate(val) : undefined
  }

  /** Letztes blockiertes Datum. */
  get last() {
    const val = this[propKeys.last]
    return val ? toDate(val) : undefined
  }

  /** Anzahl blockierter Datumsbereiche. */
  get length() {
    return this.blocked.length
  }

  sliceMonth(date) {
    return this.sliceDays(
      startOfMonth(makeDate(date)),
      endOfMonth(makeDate(date)),
    )
  }

  /**
   * Berechnet alle Tage eines Monats, so dass sliceCalenderMonth()[0] immer
   * der Start der Woche darstellt (d.h. auch, dass das erste Element zum
   * Vormonat gehören kann, wenn der Monat nicht am Wochenanfang beginnt).
   *
   * @param {DateInput} date Datum, dessen Monat als Grundlage dient
   * @param {boolean} constantNumberOfWeeks Konstant 42 Day-Elemente erzeugen.
   *   Wenn `false` wird eine ggf. leere "Füllwoche" am Ende eingefügt. Dies
   *   ist hilfreich, wenn eine konstante Höhe beim Rendern gewünscht ist.
   * @returns {Day[]}
   */
  sliceCalendarMonth(date, constantNumberOfWeeks = true) {
    const start = startOfWeek(startOfMonth(makeDate(date))),
          end = endOfWeek(endOfMonth(makeDate(date)))

    if (constantNumberOfWeeks) {
      const diff = 42 /* 6 weeks */ - Math.ceil(absDiffDays(start, end))
      if (diff > 0) {
        addDays(end, diff)
      }
    }
    return this.sliceDays(start, end)
  }

  sliceDays(start, end) {
    const result = []
    let curr = makeDate(start)
    curr.setHours(12, 0, 0, 0)

    /** Index für `this.blocked` */
    let group = this._findGroupIndexFor(start)

    while (!isAfter(curr, end)) {
      let blocked = false,
          bBefore,
          bAfter

      if (this.min && isAfter(this.min, curr) || this.max && isBefore(this.max, curr)) {
        // curr < min oder max < curr
        blocked = true
      }
      if (group < this.length) {
        // groupIndex ist gültig
        const blockedGroup = this.blocked[group]

        if (!blocked && blockedGroup.contains(curr)) {
          blocked = true
        }
        if (isAfter(curr, blockedGroup.end)) {
          // curr > group.end, zu nächster Gruppe wechseln
          ++group
        }
      }
      if (!blocked) {
        // Wenn frei, geben wir dem Day die vorausgehenden/nachfolgenden
        // blockierten Daten mit. Wir sparen uns damit jedesmal erneut
        // über diese Collection zu iterieren.
        if (this.length === 0) {
          // keine blockierten Zeiträume
          bBefore = this.min || null
          bAfter = this.max || null
        } else if (group === 0) {
          // es gibt keine vorausgehende Gruppe
          bBefore = this.min || null
          bAfter = this.blocked[group].start
        } else if (group === this.length) {
          // es gibt keine nachfolgende Gruppe
          bBefore = this.blocked[group - 1].end
          bAfter = this.max || null
        } else {
          // Gruppe ist von anderen Gruppen eingeschlossen
          bBefore = this.blocked[group - 1].end
          bAfter = this.blocked[group].start
        }
      }

      result.push(new Day(curr, {
        blocked,
        group,
        bBefore,
        bAfter,
      }))

      curr = addDays(curr, 1)
    }
    return result
  }

  /** @private */
  _findGroupIndexFor(date) {
    for (let i = 0; i < this.length; ++i) {
      if (isAfter(this.blocked[i].end, date)) {
        return i
      }
    }
    return this.length
  }

  get [Symbol.toStringTag]() {
    return "Collection"
  }
}
