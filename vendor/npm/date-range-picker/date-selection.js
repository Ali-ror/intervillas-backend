import { addDays, addMilliseconds, eachDayOfInterval } from "date-fns"
import { DateRange } from "./DateRange"
import { absDiffDays } from "./utils"

class DateSelection {
  /** @param {number | (Day) => number} [rangeSize] */
  constructor(rangeSize) {
    if (typeof rangeSize === "function") {
      this.rangeSize = rangeSize
    } else {
      this.rangeSize = () => rangeSize || 0
    }

    // cache
    this.lastResult = null
  }

  /**
   * @param {{ date: Date | number }} a
   * @param {{ date: Date | number }} b
   */
  select(a, b) {
    const range = DateRange.ordered(a.date, b.date)
    if (this.lastResult && this.lastResult.range.isSame(range)) {
      return this.lastResult
    }

    this.lastResult = this._calculate(range, a)
    return this.lastResult
  }

  /**
   * @param {DateRange} range
   * @param {Day} day
   * @return {DateSelection.Result}
   */
  _calculate(range, day) {
    // minimale Auswahlgröße (in Tagen)
    const min = Math.max(...eachDayOfInterval(range).map(date => this.rangeSize(date)))
    if (min <= 0) {
      return new DateSelection.Result(range, min, false)
    }

    // Metriken für die Berechnungen
    const availableDays = day.groupAvailableDays(),
          [blockedBefore, blockedAfter] = day.groupRange

    // Lückenfüller
    if (availableDays <= min) {
      range.start = addMilliseconds(blockedBefore, 1)
      range.end = addMilliseconds(blockedAfter, -1)

      return new DateSelection.Result(range, min, true)
    }

    const deltaCurr = absDiffDays(range.start, range.end)
    if (deltaCurr >= min) {
      // Zeitraum zwischen den gewählten Tagen groß genug für min-Range
      return new DateSelection.Result(range, min, false)
    }

    const deltaAfter = blockedAfter
      ? absDiffDays(range.start, blockedAfter)
      : Infinity
    if (deltaAfter < min) {
      // Zeitraum nach letzter Auswahl reicht nicht, also verschieben
      // wir die erste Auswahl ein Stück nach vorn
      range.start = addDays(range.start, deltaAfter - min)
    }

    range.end = addDays(range.start, min)

    // Wenn Start/Ende sich verändern, kann sich min auch verändert haben,
    // also muss das noch mindestens einmal durchgerechnet werden.
    return this._calculate(range, day)
  }
}

DateSelection.Result = class Result {
  constructor(range, min, finished) {
    this.range = range
    this._min = min
    this.finished = finished
    this.typeKey = undefined
  }

  get min() {
    return (this.typeKey === "days") ? this._min + 1 : this._min
  }
}

export default DateSelection
