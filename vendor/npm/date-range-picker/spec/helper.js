global.expect = require("chai").expect

global.fit = function(name, cb) {
  context.only("current focus group", () => {
    it(name, cb)
  })
}
