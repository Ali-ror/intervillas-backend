import { isAfter, isBefore, isSameDay } from "date-fns"
import { absDiffDays, makeDate } from "../utils"

/**
 * Day repräsentiert einen Tag im Kalender.
 *
 * Man kann einen Tag "auswählen", sofern dieser nicht blockiert ist.
 *
 * Mehrere Tage sind zusammen in einer "Gruppe" organisiert, das einem
 * Consumer erlaubt, nur Tage auszuwählen, die Teil derselben Gruppe
 * sind. Einer Gruppe sind auch die ersten Daten vor bzw. nach dem
 * Kalender-Tag zugeordnet, die wieder blockiert sind.
 */
export default class Day {
  /**
   * Konstruiert ein Datum zur Anzeige im Kalender.
   * @param {Date | string | number} date
   * @param {object} [options={}]
   * @param {boolean} [options.blocked=false] Ist das Datum blockiert?
   * @param {number} options.group Zu welcher Grupper blockierter Daten gehört diese Instanz?
   * @param {Date | number} [options.bBefore] Falls nicht blockiert, was ist das erste blockierte Datum *vor* `date`?
   * @param {Date | number} [options.bAfter] Falls nicht blockiert, was ist das erste blockierte Datum *nach* `date`?
   */
  constructor(date, options = {}) {
    this.date = makeDate(date)
    this.options = options
    this.annotations = {}
  }

  get group() {
    return this.options.blocked ? -1 : this.options.group
  }
  get groupRange() {
    return this.options.blocked ? [null, null] : [this.options.bBefore, this.options.bAfter]
  }

  /**
   * Anzahl der Tage, die in der aktuellen Gruppe zur Verfügung stehen. Bei einem
   * offenen Intervall ist dies Infinity.
   * @return {number}
   */
  groupAvailableDays() {
    if (!this.options.bBefore || !this.options.bAfter) {
      return Infinity
    }
    return absDiffDays(this.options.bAfter, this.options.bBefore)
  }

  get blocked() {
    return !!this.options.blocked
  }
  set blocked(val) {
    this.options.blocked = !!val
  }

  get blockedHalfs() {
    return {
      am: this.blocked || isSameDay(this.date, this.options.bBefore),
      pm: this.blocked || isSameDay(this.date, this.options.bAfter),
    }
  }

  get free() {
    return !this.options.blocked
  }
  set free(val) {
    this.options.blocked = !val
  }

  clone() {
    const clonedOptions = Object.assign({}, this.options)
    return new Day(this.date, clonedOptions)
  }

  toString() {
    return this.date.getDate().toString()
  }

  /**
   * Vergleicht diese Instanz mit einer anderen. Gibt -1 (wenn diese < andere
   * Instanz), 0 (diese == andere Instanz) oder 1 (diese > andere Instanz)
   * zurück.
   *
   * @see Array.prototype.sort
   * @param {Day} other
   * @returns {number}
   */
  compare(other) {
    if (isBefore(this.date, other.date)) {
      return -1
    }
    if (isAfter(this.date, other.date)) {
      return 1
    }
    return 0
  }

  /**
   * Prüft, ob diese und eine andere Instanz beide frei und in derselben
   * Gruppe sind.
   * @param {Day} other
   * @returns {boolean}
   */
  matches(other) {
    return !this.blocked && !other.blocked && this.group === other.group
  }

  get [Symbol.toStringTag]() {
    return "Day"
  }
}
