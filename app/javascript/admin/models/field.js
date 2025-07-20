import { formatISO } from "date-fns"
import validation from "./validation"
import { makeDate } from "../../lib/DateFormatter"

export default class Field {
  constructor(name, schema) {
    this.name = name
    this.label = schema.label
    this.type = schema.type
    this.externalErrors = []

    const defaultVal = "default" in schema
      ? schema["default"]
      : null
    this.default = defaultVal
    this.value = defaultVal
    this.dirty = false

    this.constraints = {}
    Object.keys(schema).forEach(k => {
      if (k in this) {
        // skip known fields
        return
      }

      this.constraints[k] = schema[k]
    })

    if (!this.type) {
      if (this.constraints.date) {
        this.type = "date"
      } else if (this.constraints.datetime) {
        this.type = "datetime"
      } else if (this.constraints.numericality) {
        if (this.constraints.numericality.onlyInteger) {
          this.type = "integer"
        } else {
          this.type = "number"
        }
      }
    }
  }

  get() {
    return (!this.dirty && !this.value)
      ? this.default
      : this.value
  }

  set(val) {
    this.dirty = true
    this.value = this.coerce(val)
  }

  toJSON() {
    const isString = o => typeof o === "string" || o instanceof String,
          nanToNull = o => isNaN(o) ? null : o

    switch (this.type) {
    case "date":
      return this.value && formatISO(makeDate(this.value), { representation: "date" })

    case "datetime":
      return this.value && formatISO(makeDate(this.value))

    case "integer":
      return isString(this.value) ? nanToNull(parseInt(this.value, 10)) : this.value

    case "number":
      return isString(this.value) ? nanToNull(parseFloat(this.value)) : this.value

    default:
      return this.value
    }
  }

  coerce(val) {
    switch (this.type) {
    case "date":
    case "datetime":
      return val && makeDate(val)

    case "integer":
      return typeof val === "string" || val instanceof String
        ? parseInt(val, 10)
        : val

    case "number":
      return typeof val === "string" || val instanceof String
        ? parseFloat(val)
        : val

    default:
      return val
    }
  }

  errors() {
    const result = validation.single(this.value, this.constraints, { format: "simple" })

    if (!result) {
      return this.externalErrors.slice(0)
    }
    for (let i = 0, len = this.externalErrors.length; i < len; ++i) {
      const err = this.externalErrors[i]
      if (!result.includes(err)) {
        result.push(err)
      }
    }
    return result
  }

  setErrors(errList) {
    if (Array.isArray(errList)) {
      this.externalErrors = [...errList]
    }
  }
}
