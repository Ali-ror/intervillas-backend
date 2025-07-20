import {
  addDays, addMonths, addMilliseconds,
  eachDayOfInterval,
  formatISO,
  getDaysInMonth,
  parseISO,
  setHours,
  startOfDay, endOfDay,
} from "date-fns"

import Collection from "../../src/pickable/collection"

const collectionDefaults = {
  length: 0,
  min:    undefined,
  max:    undefined,
  first:  undefined,
  last:   undefined,
}

const expectCollection = (collection, expectations) => {
  expect(collection).to.be.a("Collection")

  Object.keys(collectionDefaults).forEach(f => {
    const actual = collection[f],
          expected = expectations[f] || collectionDefaults[f]

    if (expected instanceof Date) {
      if (actual) {
        const diff = Math.abs(expected.getTime() - actual.getTime()),
              msg = `collection.${f}: actual(${formatISO(actual)}) != expected(${formatISO(expected)}), diff(${diff / 1000}s)`
        expect(diff, msg).to.equal(0)
      } else {
        expect(actual).not.to.be.undefined
        expect(actual).not.to.be.null
      }
    } else {
      const msg = `collection.${f}: actual(${actual}) != expected(${expected})`
      expect(actual, msg).to.equal(expected)
    }
  })
}

describe("Collection", function() {
  describe("#new", function() {
    context("accepting blank values", function() {
      it("empty list", function() {
        const c = new Collection()
        expectCollection(c, {})
      })
      it("null", function() {
        const c = new Collection(null)
        expectCollection(c, {})
      })
      it("undefined", function() {
        const c = new Collection(undefined)
        expectCollection(c, {})
      })
    })
    context("accepting single element", function() {
      it("of type Date", function() {
        const ref = new Date(),
              c = new Collection(ref)
        expectCollection(c, {
          length: 1,
          first:  startOfDay(ref),
          last:   endOfDay(ref),
        })
      })
      it("of type string", function() {
        const ref = "2017-08-12",
              c = new Collection(ref)
        expectCollection(c, {
          length: 1,
          first:  startOfDay(parseISO(ref)),
          last:   endOfDay(parseISO(ref)),
        })
      })
    })
    context("accepting array of single elements", function() {
      const ref1 = new Date(),
            ref2 = addDays(new Date(), 2),
            ref3 = addDays(new Date(), 10)
      it("takes one", function() {
        const c = new Collection([ref1])
        expectCollection(c, {
          length: 1,
          first:  startOfDay(ref1),
          last:   endOfDay(ref1),
        })
      })
      it("takes many", function() {
        const c = new Collection([ref1, ref2, ref3])
        expectCollection(c, {
          length: 3,
          first:  startOfDay(ref1),
          last:   endOfDay(ref3),
        })
      })
      it("filters null/undefined", function() {
        const c = new Collection([ref1, null, ref2, undefined, false, ref3])
        expectCollection(c, {
          length: 3,
          first:  startOfDay(ref1),
          last:   endOfDay(ref3),
        })
      })
      it("reorders ranges", function() {
        const c = new Collection([ref2, ref3, ref1])
        expectCollection(c, {
          length: 3,
          first:  startOfDay(ref1),
          last:   endOfDay(ref3),
        })
      })
      it("merges adjacent ranges", function() {
        const ref4 = addDays(ref1, 1),
              c = new Collection([ref1, ref2, ref3, ref4])

        expectCollection(c, {
          length: 2, // merge(ref1, ref4, ref2) + ref3
          first:  startOfDay(ref1),
          last:   endOfDay(ref3),
        })
      })
    })
    it("accepts an array of arrays", function() {
      const ref1 = [new Date(), addDays(new Date(), 1)],
            ignored = [new Date(), addDays(new Date(), 10), addMonths(new Date(), 1)],
            ref2 = [addDays(new Date(), 10), addDays(new Date(), 12)],
            c = new Collection([[...ref1], [...ignored], [...ref2]])
      expectCollection(c, {
        length: 2,
        first:  ref1[0],
        last:   ref2[1],
      })
    })
    it("accepts mixed arrays", function() {
      const ref1 = [new Date(), addDays(new Date(), 1)],
            ref2 = addDays(new Date(), 10),
            c = new Collection([[...ref1], ref2])
      expectCollection(c, {
        length: 2,
        first:  ref1[0],
        last:   endOfDay(ref2),
      })
    })
    it("allows double construction", function() {
      const ref1 = [new Date(), addDays(new Date(), 1)],
            ref2 = addDays(new Date(), 10),
            c = new Collection([[...ref1], ref2]),
            c2 = new Collection(c.blocked, c.min, c.max)
      expectCollection(c2, {
        length: c.length,
        first:  c.first,
        last:   c.last,
        min:    c.min,
        max:    c.max,
      })
      for (let i = 0, len = c.length; i < len; ++i) {
        expect(c2.blocked[i].isSame(c.blocked[i]), `blocked[${i}] isSame`).to.be.true
      }
    })
    describe("min/max dates", function() {
      context("without blocked dates", function() {
        const c = (min, max) => new Collection(null, min, max)
        it("handles min only", function() {
          const min = new Date()
          expectCollection(c(min, null), { min })
        })
        it("handles max only", function() {
          const max = new Date()
          expectCollection(c(null, max), { max })
        })
        it("handles min < max", function() {
          const min = new Date(),
                max = addDays(new Date(), 1)
          expectCollection(c(min, max), { min, max })
        })
        it("max < min throws error", function() {
          const min = new Date(),
                max = addDays(new Date(), 1)
          expect(() => c(max, min)).to.throw(RangeError)
        })
      })
      context("with blocked dates", function() {
        const ref1 = new Date(),
              ref2 = addDays(new Date(), 10),
              c = (min, max) => new Collection([ref1, ref2], min, max)

        it("handles min < first", function() {
          const min = addDays(ref1, -1)
          expectCollection(c(min, null), {
            length: 2,
            min,
            first:  startOfDay(ref1),
            last:   endOfDay(ref2),
          })
        })
        it("handles first < min < last", function() {
          const min = addDays(ref1, 1)
          expectCollection(c(min, null), {
            length: 1,
            min,
            first:  startOfDay(ref2),
            last:   endOfDay(ref2),
          })
        })
        it("handles last < min", function() {
          const min = addDays(ref2, 1)
          expectCollection(c(min, null), { min })
        })
        it("handles last < max", function() {
          const max = addDays(ref2, 1)
          expectCollection(c(null, max), {
            length: 2,
            max,
            first:  startOfDay(ref1),
            last:   endOfDay(ref2),
          })
        })
        it("handles first < max < last", function() {
          const max = addDays(ref2, -1)
          expectCollection(c(null, max), {
            length: 1,
            max,
            first:  startOfDay(ref1),
            last:   endOfDay(ref1),
          })
        })
        it("handles max < first", function() {
          const max = addDays(ref1, -1)
          expectCollection(c(null, max), { max })
        })
        it("handles min < first, last < max", function() {
          const min = addDays(ref1, -1),
                max = addDays(ref2, 1)
          expectCollection(c(min, max), {
            length: 2,
            min,
            max,
            first:  startOfDay(ref1),
            last:   endOfDay(ref2),
          })
        })
        it("handles first < min, max < last", function() {
          const min = addDays(ref1, 1),
                max = addDays(ref2, -1)
          expectCollection(c(min, max), { length: 0, min, max })
        })
        it("max < min throws error", function() {
          const min = addDays(ref1, 1),
                max = addDays(ref2, -1)
          expect(() => c(max, min)).to.throw(RangeError)
        })
        it("allows double construction", function() {
          const min = addDays(ref1, 1),
                max = addDays(ref2, -1),
                c = new Collection([ref1, ref2], min, max),
                c2 = new Collection(c.blocked, c.min, c.max)
          expectCollection(c2, {
            length: c.length,
            first:  c.first,
            last:   c.last,
            min:    c.min,
            max:    c.max,
          })
          for (let i = 0, len = c.length; i < len; ++i) {
            expect(c2.blocked[i].isSame(c.blocked[i]), `blocked[${i}] isSame`).to.be.true
          }
        })
        it("moves min forward, when min = first", function() {
          const min = addMilliseconds(startOfDay(ref1), -1) // adjacent
          expectCollection(c(min, null), {
            length: 1,
            first:  startOfDay(ref2),
            last:   endOfDay(ref2),
            min:    endOfDay(ref1),
          })
        })
        it("moves max back, when last = max", function() {
          const max = addMilliseconds(endOfDay(ref2), 1) // adjacent
          expectCollection(c(null, max), {
            length: 1,
            first:  startOfDay(ref1),
            last:   endOfDay(ref1),
            max:    startOfDay(ref2),
          })
        })
      })
      context("with blocked range", function() {
        const first = new Date(2023, 8, 10, 12, 0, 0),
              last = addDays(new Date(2023, 8, 10, 12, 0, 0), 10),
              c = (min, max) => new Collection([[first, last]], min, max)

        it("handles first < min < max < last", function() {
          const min = addDays(first, 2),
                max = addDays(last, -2)
          expectCollection(c(min, max), {
            length: 0,
            min,
            max:    min,
          })
        })
      })
    })
    it("doesn't mutate its args", function() {
      const min = new Date(),
            max = addDays(new Date(), 5),
            ref = addDays(new Date(), 3),
            backup = [ref, min, max],
            c = new Collection(ref, min, max)
      expect(ref === backup[0], "ref was mutated").to.be.true
      expect(min === backup[1], "min was mutated").to.be.true
      expect(max === backup[2], "max was mutated").to.be.true
      expectCollection(c, {
        length: 1,
        min,
        max,
        first:  startOfDay(ref),
        last:   endOfDay(ref),
      })
    })

    context("data found in the wild", function() {
      it("works", function() {
        const blocked = [["2019-12-11", "2020-01-11"]],
              min = parseISO("2019-12-31"),
              max = parseISO("2020-01-10")

        expect(() => new Collection(blocked, min, max)).to.not.throw()
      })
    })
  })

  describe("#sliceMonth", function() {
    it("returns a list of days", function() {
      const ref = new Date(),
            set = new Collection(),
            slice = set.sliceMonth(ref)

      expect(slice).to.be.an("Array")
      for (let i = slice.length - 1; i >= 0; --i) {
        const day = slice[i]
        expect(day).to.be.a("Day")
        expect(day.blocked, "blocked").to.be.false
      }
    })

    const refMonth = parseISO("2017-05-01")
    const expectBlocked = function(collection, test) {
      const slice = collection.sliceMonth(refMonth)
      for (let i = 1, dim = getDaysInMonth(refMonth); i < dim; ++i) {
        const day = slice[i - 1],
              blocked = test(i)
        // console.log({ [i]: day.blocked, blocked })
        expect(day.blocked, `blocked on ${formatISO(day.date)}`).to.equal(blocked)
      }
    }

    context("given blocked days", function() {
      const wholeDay = addDays(refMonth, 7)

      ;[true, false].forEach(inclStart => {
        context(`start ${inclStart ? "in" : "ex"}clusive`, () => {
          [true, false].forEach(inclEnd => {
            it(`blocks when end ${inclEnd ? "in" : "ex"}clusive`, () => {
              const r = [
                      setHours(addDays(refMonth, 16), inclStart ? 8 : 16),
                      setHours(addDays(refMonth, 20), inclEnd ? 16 : 8),
                    ],
                    list = [8 /* whole day */, /* always in r */ 18, 19, 20]
              if (inclStart) {
                list.push(17)
              }
              if (inclEnd) {
                list.push(21)
              }

              expectBlocked(
                new Collection([wholeDay, r]),
                dom => list.includes(dom),
              )
            })
          })
        })
      })
    })

    context("given min/max", function() {
      const min = addDays(refMonth, 4), // 2017-05-01 + 4 = 2017-05-05
            max = addDays(refMonth, 24),
            c = (min, max) => new Collection(null, min, max)

      it("blocks some days when given both", function() {
        expectBlocked(c(min, max), dom => dom < 5 || dom >= 25)
      })

      it("blocks some days when given only min", function() {
        expectBlocked(c(min, null), dom => dom < 5)
      })

      it("blocks some days when given only max", function() {
        expectBlocked(c(null, max), dom => dom >= 25)
      })
    })
  })

  // "private"
  describe("#_findGroupIndexFor", function() {
    const min = parseISO("2016-02-02"),
          bl1 = parseISO("2016-02-05"),
          bl2 = parseISO("2016-02-08"),
          max = parseISO("2016-02-11"),
          r = { start: parseISO("2016-01-30"), end: parseISO("2016-02-18") }

    // Ergebnis ist aussschließlich von den blockierten Daten abhängig
    const test = (min, max) => {
      const subject = new Collection([bl1, bl2], min, max)

      return function() {
        for (let date of eachDayOfInterval(r)) {
          const expected = (endOfDay(bl1) > date)
            ? 0
            : endOfDay(bl2) > date
              ? 1
              : 2

          expect(subject._findGroupIndexFor(date), formatISO(date)).to.equal(expected)
        }
      }
    }

    it("given neither min nor max", test(null, null))
    it("given only min", test(min, null))
    it("given only max", test(null, max))
    it("given both min and max", test(min, max))
  })
})
