import { translate } from "@digineo/vue-translate"

export default class Caption {
  static from(...things) {
    return things.reduce((result, thing) => {
      if (Array.isArray(thing)) {
        result.push(...Caption.from(...thing))
      } else if (typeof thing === Caption) {
        result.push(Caption)
      } else {
        Object.keys(thing).forEach(k => {
          result.push(new Caption(k, thing[k]))
        })
      }
      return result
    })
  }

  constructor(className, translationKey) {
    this.className = className
    this.translationKey = translationKey
  }

  toString() {
    return translate(this.translationKey)
  }
}
