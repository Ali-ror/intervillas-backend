import { addDays, isSameDay, setHours } from "date-fns"

describe("insanity", function() {
  it("is defined as doing the same thing over and over again...", function() {
    expect(false).to.equal(false)
    expect(false).to.be.false
  })

  it("...and expecting different results", function() {
    expect(true).to.equal(true)
    expect(true).to.be.true
  })
})

describe("isSameDay", function() {
  it("is true for identical dates", function() {
    const a = new Date()
    expect(isSameDay(a, a)).to.be.true
  })
  it("is true for cloned dates", function() {
    const a = new Date(),
          b = new Date(a)
    expect(isSameDay(a, b)).to.be.true
  })
  it("is true for dates on the same day", function() {
    const ref = new Date(),
          a = setHours(ref, 11),
          b = setHours(ref, 12)
    expect(isSameDay(a, b)).to.be.true
  })
  it("is false for dates on the different days", function() {
    const a = new Date(),
          b = addDays(a, 1)
    expect(isSameDay(a, b)).to.be.false
  })
})
