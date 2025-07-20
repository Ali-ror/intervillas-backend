import { fmt } from "./utils"
import { translate } from "@digineo/vue-translate"

export default class Message {
  static fromResult(id, result) {
    return new Message(id, {
      min:            result.min,
      start:          result.range.start,
      startFormatted: fmt(result.range.start),
      end:            result.range.end,
      endFormatted:   fmt(result.range.end),
      type:           result.type,
    })
  }

  constructor(id, attrs = {}) {
    this.id = id

    Object.keys(attrs).forEach(key => {
      Object.defineProperty(this, key, {
        value:        attrs[key],
        configurable: false,
        enumerable:   true,
      })
    })
  }

  toString() {
    switch (this.id) {
    case "fill-in":
      return translate("drp.msg.fill_in", {
        start: this.startFormatted,
        end:   this.endFormatted,
      })
    case "min-range":
      return translate("drp.msg.min_range", {
        min:  this.min,
        type: this.type,
      })
    }
  }
}
