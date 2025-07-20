import { formatISO, parseISO, setDefaultOptions } from "date-fns"
import { de } from "date-fns/locale"
import { ensureDate, fmt, getLocaleData } from "../src/utils"

const expectDate = (m, kv) => {
  Object.keys(kv).forEach(k => {
    expect(m[k](), k).to.equal(kv[k])
  })
}

describe("#ensureDate", function() {
  it("sets the hour to a default", function() {
    const t = "2017-05-06T13:14:15.6789Z",
          d = ensureDate(t)
    expect(formatISO(d)).to.equal("2017-05-06T12:00:00+02:00")
  })

  it("adjusting can be disabled", function() {
    const t = "2017-05-06T13:14:15.6789Z"
    expectDate(ensureDate(t, false), {
      getUTCHours:        13,
      getUTCMinutes:      14,
      getUTCSeconds:      15,
      getUTCMilliseconds: 678,
    })
  })

  ;[ // if these fail, re-run with TZ=Europe/Berlin
    { hour: 0, date: "2017-05-06T00:00:00+02:00" },
    { hour: 12, date: "2017-05-06T12:00:00+02:00" },
    { hour: 18, date: "2017-05-06T18:00:00+02:00" },
  ].forEach(function({ hour, date }) {
    it(`sets the hour to ${hour}`, function() {
      const t = "2017-05-06T13:14:15.6789Z",
            d = ensureDate(t, hour)

      expect(formatISO(d)).to.equal(date)
    })
  })

  it("throws a RangeError for anormal hours", () => {
    expect(() => ensureDate(new Date(), -1)).to.throw(RangeError)
    expect(() => ensureDate(new Date(), 0)).to.not.throw
    expect(() => ensureDate(new Date(), 23)).to.not.throw
    expect(() => ensureDate(new Date(), 24)).to.throw(RangeError)
  })
})

describe("#fmt", function() {
  const ref = "2017-01-02T11:22:33.4567+08:15",
        d = parseISO(ref)

  it("formats a number", function() {
    expect(fmt(d.valueOf())).to.equal("01/02/2017")
  })
  it("formats a date", function() {
    expect(fmt(d)).to.equal("01/02/2017")
  })
  it("formats a string", function() {
    expect(fmt(ref)).to.equal("01/02/2017")
  })
})

describe("LocaleData", function() {
  describe("en", function() {
    const instance = () => getLocaleData("en")

    it("builds daysOfWeek", function() {
      expect(instance().daysOfWeek).to.deep.equal([
        { dow: 0, short: "Sun", long: "Sunday" },
        { dow: 1, short: "Mon", long: "Monday" },
        { dow: 2, short: "Tue", long: "Tuesday" },
        { dow: 3, short: "Wed", long: "Wednesday" },
        { dow: 4, short: "Thu", long: "Thursday" },
        { dow: 5, short: "Fri", long: "Friday" },
        { dow: 6, short: "Sat", long: "Saturday" },
      ])
    })

    it("builds monthNames", function() {
      expect(instance().monthNames).to.deep.equal([
        { short: "Jan", long: "January" },
        { short: "Feb", long: "February" },
        { short: "Mar", long: "March" },
        { short: "Apr", long: "April" },
        { short: "May", long: "May" },
        { short: "Jun", long: "June" },
        { short: "Jul", long: "July" },
        { short: "Aug", long: "August" },
        { short: "Sep", long: "September" },
        { short: "Oct", long: "October" },
        { short: "Nov", long: "November" },
        { short: "Dec", long: "December" },
      ])
    })
  })

  describe("de", function() {
    const instance = () => getLocaleData("de")

    before(function() {
      setDefaultOptions({ locale: de, weekStartsOn: de.options.weekStartsOn })
    })

    after(function() {
      setDefaultOptions({})
    })

    it("builds daysOfWeek", function() {
      expect(instance().daysOfWeek).to.deep.equal([
        { dow: 1, short: "Mo", long: "Montag" },
        { dow: 2, short: "Di", long: "Dienstag" },
        { dow: 3, short: "Mi", long: "Mittwoch" },
        { dow: 4, short: "Do", long: "Donnerstag" },
        { dow: 5, short: "Fr", long: "Freitag" },
        { dow: 6, short: "Sa", long: "Samstag" },
        { dow: 0, short: "So", long: "Sonntag" },
      ])
    })

    it("builds monthNames", function() {
      expect(instance().monthNames).to.deep.equal([
        { short: "Jan", long: "Januar" },
        { short: "Feb", long: "Februar" },
        { short: "Mär", long: "März" },
        { short: "Apr", long: "April" },
        { short: "Mai", long: "Mai" },
        { short: "Jun", long: "Juni" },
        { short: "Jul", long: "Juli" },
        { short: "Aug", long: "August" },
        { short: "Sep", long: "September" },
        { short: "Okt", long: "Oktober" },
        { short: "Nov", long: "November" },
        { short: "Dez", long: "Dezember" },
      ])
    })
  })
})
