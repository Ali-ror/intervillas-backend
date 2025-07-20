import {
  toDate,
  min, max,
  minTime, maxTime,
} from "date-fns"

/**
 * Minimal re-implementation of moment-range's DateRange type.
 */
export class DateRange {
  /**
   * Erzeugt eine DateRange von min(a,b)..max(a,b)
   * @param {Date | number} a
   * @param {Date | number} b
   * @returns {DateRange}
   */
  static ordered(a, b) {
    const start = min([a, b]),
          end = max([a, b])

    return new DateRange(start, end)
  }

  /**
   * Constructs a date range.
   * Internally, dates are handled as numbers.
   *
   * @param {Date | number} start start date
   * @param {Date | number} end end date
   */
  constructor(start, end) {
    let s = toDate(start ?? minTime)
    let e = toDate(end ?? maxTime)

    this.start = s.valueOf()
    this.end = e.valueOf()
  }

  /** @param {DateRange} other */
  adjacent(other) {
    const sameStartEnd = this.start === other.end,
          sameEndStart = this.end === other.start

    return (sameStartEnd && other.start <= this.start) || (sameEndStart && other.end >= this.end)
  }

  /** @param {DateRange} other */
  intersect(other) {
    const { start, end } = this,
          { start: otherStart, end: otherEnd } = other,
          isZeroLength = start === end,
          isOtherZeroLength = otherStart === otherEnd

    // Zero-length ranges
    if (isZeroLength) {
      if (start === otherStart || start === otherEnd) {
        return undefined
      } else if (start > otherStart && start < otherEnd) {
        return new DateRange(start, end)
      }
    } else if (isOtherZeroLength) {
      if (otherStart === start || otherStart === end) {
        return undefined
      } else if (otherStart > start && otherStart < end) {
        return new DateRange(otherStart, otherStart)
      }
    }
    // Non zero-length ranges
    if (start <= otherStart && otherStart < end && end < otherEnd) {
      return new DateRange(otherStart, end)
    }
    if (otherStart < start && start < otherEnd && otherEnd <= end) {
      return new DateRange(start, otherEnd)
    }
    if (otherStart < start && start <= end && end < otherEnd) {
      return new DateRange(start, end)
    }
    if (start <= otherStart && otherStart <= otherEnd && otherEnd <= end) {
      return new DateRange(otherStart, otherEnd)
    }
    return undefined
  }

  /** @param {DateRange} other */
  overlaps(other, options = { adjacent: false }) {
    const intersects = this.intersect(other) !== undefined
    if (options.adjacent && !intersects) {
      return this.adjacent(other)
    }
    return intersects
  }

  /** @param {DateRange} other */
  add(other, options = { adjacent: false }) {
    if (this.overlaps(other, options)) {
      return new DateRange(Math.min(this.start, other.start), Math.max(this.end, other.end))
    }
    return undefined
  }

  /** @param {DateRange} other */
  isSame(other) {
    return this.start === other.start && this.end === other.end
  }

  /** @param {DateRange | Date | number} other */
  contains(other) {
    // the orginial additional deals with exclusive start/end values;
    // we'll always include them here.
    let otherStart, otherEnd
    if (other instanceof DateRange) {
      otherStart = other.start
      otherEnd = other.end
    } else {
      otherStart = otherEnd = toDate(other).valueOf()
    }

    const { start, end } = this,
          startInRange = start <= otherStart,
          endInRange = otherEnd <= end

    return startInRange && endInRange
  }
}
