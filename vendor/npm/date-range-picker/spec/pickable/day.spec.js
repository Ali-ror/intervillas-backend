import { addSeconds } from "date-fns"
import Day from "../../src/pickable/day"

describe("Day", function() {
  it("can be displayed", function() {
    const p = new Day("2017-07-13")

    expect(p.toString()).to.equal("13")
    expect(`${p}`).to.equal("13")
  })

  it("has a string tag", function() {
    expect(new Day).to.be.a("Day")
  })

  describe("props", function() {
    describe("blocked", function() {
      beforeEach(function() {
        this.subject = new Day(null, { blocked: true, group: 42 })
      })

      it("sets/gets .blocked", function() {
        expect(this.subject.blocked, "blocked before").to.be.true
        expect(this.subject.free, "free before").to.be.false

        this.subject.blocked = false

        expect(this.subject.blocked, "blocked after").to.be.false
        expect(this.subject.free, "free before").to.be.true
      })

      it("sets/gets .free", function() {
        expect(this.subject.free, "free before").to.be.false
        expect(this.subject.blocked, "blocked before").to.be.true

        this.subject.free = true

        expect(this.subject.free, "free after").to.be.true
        expect(this.subject.blocked, "blocked after").to.be.false
      })

      it("gets .group", function() {
        expect(this.subject.group).to.equal(-1)
      })

      it("setting/modifying .group fails", function() {
        expect(() => this.subject.group++).to.throw(TypeError)
        expect(this.subject.group).to.equal(-1)

        expect(() => this.subject.group = 21).to.throw(TypeError)
        expect(this.subject.group).to.equal(-1)
      })
    })

    describe("not blocked", function() {
      beforeEach(function() {
        this.subject = new Day(null, { blocked: false, group: 42 })
      })

      it("gets .group", function() {
        expect(this.subject.group).to.equal(42)
      })

      it("setting/modifying .group fails", function() {
        expect(() => this.subject.group++).to.throw(TypeError)
        expect(this.subject.group).to.equal(42)

        expect(() => this.subject.group = 21).to.throw(TypeError)
        expect(this.subject.group).to.equal(42)
      })
    })
  })

  describe("#compare", function() {
    it("a <=> a is 0", function() {
      const a = new Day("2016-02-29")
      expect(a.compare(a)).to.equal(0)
    })

    it("a <=> b (with same underlying date) is 0", function() {
      const ref = new Date(),
            a = new Day(ref),
            b = new Day(ref)
      expect(a.compare(b)).to.equal(0)
    })

    it("a <=> b is < 0 if a is before b", function() {
      const a = new Day(new Date()),
            b = new Day(addSeconds(new Date(), 1))
      expect(a.compare(b)).to.lt(0)
    })

    it("a <=> b is > 0 if a is before b", function() {
      const b = new Day(addSeconds(new Date(), -1)),
            a = new Day(new Date())
      expect(a.compare(b)).to.gt(0)
    })
  })
})
