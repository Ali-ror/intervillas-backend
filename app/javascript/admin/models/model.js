import Field from "./field"

const compileSchema = fields => {
  return Object.keys(fields).reduce((schema, name) => {
    schema[name] = () => new Field(name, fields[name])
    return schema
  }, {})
}

const schemaKey = "_attributes"

export class Base {
  constructor(schema, data) {
    Object.defineProperty(this, schemaKey, {
      enumerable:   true,
      writable:     false,
      configurable: false,

      value: Object.keys(schema).reduce((s, k) => {
        s[k] = schema[k]()
        return s
      }, {}),
    })

    this.update(data)
  }

  getField(name) {
    return this[schemaKey][name]
  }

  getErrorsOn(name) {
    return this.getField(name).errors()
  }

  update(data) {
    if (!data) {
      data = {}
    }

    this._eachField(f => {
      if (Object.prototype.hasOwnProperty.call(data, f.name)) {
        f.set(data[f.name])
      }
    })
  }

  clean() {
    this._eachField(f => {
      f.dirty = false
      f.value = f.value || f.default
    })
  }

  get dirty() {
    let dirty = false
    this._eachField(f => {
      if (f.dirty) {
        dirty = true
      }
    })
    return dirty
  }

  validate(clear) {
    this._eachField(f => {
      f.dirty = true
      if (clear) {
        f.setErrors([])
      }
    })
    return this.isValid
  }

  label(field) {
    return field in this[schemaKey] && this[schemaKey][field].label
  }

  get isValid() {
    const err = this.errors
    return !Object.keys(err).some(k => err[k].length > 0)
  }

  get errors() {
    return this._reduce(f => f.errors())
  }

  set errors(data) {
    this._eachField(f => f.setErrors(data[f.name]))
  }

  toJSON() {
    return this[schemaKey]
  }

  _reduce(cb) {
    return Object.keys(this[schemaKey]).reduce((list, k) => {
      list[k] = cb(this[schemaKey][k])
      return list
    }, {})
  }

  _eachField(cb) {
    Object.keys(this[schemaKey]).forEach(k => cb(this[schemaKey][k]))
  }
}

export default {
  /**
   * Provide a (dynamic) class with the protoype based on the schema for
   * the caller to inherit from. This is a hack.
   *
   * @example
   *    const base = Model.create({
   *      "name": { label: "Name", presence: true } // see Field constructor
   *    })
   *    class ThingWithName extends base {
   *      // Nothing to see here
   *    }
   *
   * @param {Object} schema
   * @returns Class
   */
  create(schema) {
    const precompiled = compileSchema(schema)

    const Model = class Model extends Base {
      constructor(data) {
        super(precompiled, data)
      }
    }

    Object.keys(precompiled).forEach(k => {
      Object.defineProperty(Model.prototype, k, {
        configurable: false,
        enumerable:   true,

        get() {
          return this[schemaKey][k].get()
        },

        set(val) {
          this[schemaKey][k].set(val)
        },
      })
    })

    return Model
  },
}
