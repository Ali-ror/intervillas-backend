import { endOfDay, parseISO, startOfDay } from "date-fns"
import { DateRange } from "../src/DateRange"

describe("DateRange", function() {
  const r = (s, e) => new DateRange(
    startOfDay(s ? parseISO(s) : startOfDay(new Date())),
    endOfDay(e ? parseISO(e) : endOfDay(new Date())),
  )

  it(".overlaps(null) throws type error", function() {
    expect(r().overlaps).to.throw(TypeError)
  })

  describe("disjunct ranges", function() {
    const a = r("2017-01-05", "2017-01-13"),
          b = r("2017-03-07", "2017-03-21")

    it("should not overlap", function() {
      expect(a.overlaps(b)).to.be.false
    })
    it("can not be merged", function() {
      expect(a.add(b)).to.be.undefined
    })
  })

  describe("containing ranges", function() {
    const a = r("2017-01-05", "2017-03-13"),
          b = r("2017-02-07", "2017-02-11")

    it("should overlap", function() {
      expect(a.overlaps(b)).to.be.true
    })
    it("can be merged", function() {
      const m = a.add(b)
      expect(m.start === a.start).to.be.true
      expect(m.end === a.end).to.be.true
    })
    it("can be merged and order doesn't matter", function() {
      const m = b.add(a)
      expect(m.start === a.start).to.be.true
      expect(m.end === a.end).to.be.true
    })
  })

  describe("overlapping ranges", function() {
    const a = r("2017-01-05", "2017-02-13"),
          b = r("2017-02-07", "2017-03-21")

    it("should overlap", function() {
      expect(a.overlaps(b)).to.be.true
    })
    it("can be merged", function() {
      const m = a.add(b)
      expect(m.start === a.start).to.be.true
      expect(m.end === b.end).to.be.true
    })
    it("can be merged and order doesn't matter", function() {
      const m = b.add(a)
      expect(m.start === a.start).to.be.true
      expect(m.end === b.end).to.be.true
    })
  })

  describe("adjacent ranges", function() {
    const a = r("2017-01-05", "2017-01-12"),
          b = r("2017-01-13", "2017-01-31")

    it("should not overlap", function() {
      expect(a.overlaps(b)).to.be.false
    })
    it("should have tiny difference", function() {
      expect(a.end - b.start).to.be.lte(1)
    })
    it("can not be merged", function() {
      expect(a.add(b)).to.be.undefined
    })
  })
})
