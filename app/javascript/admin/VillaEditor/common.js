import Utils from "../../intervillas-drp/utils"
import { has } from "../../lib/has"
import { Villa, Domain, Category, Tag } from "./models"
import { errorsFor } from "./validators"
import { translate } from "@digineo/vue-translate"

export default {
  props: {
    villa: { type: Villa, required: true },
    api:   { type: Object, required: true },
  },

  data() {
    return {
      wasClean: true,
    }
  },

  watch: {
    ["$v.$anyDirty"](newVal) {
      if (this.wasClean && newVal) {
        this.wasClean = false
      }
    },
  },

  computed: {
    catByName() {
      return Category.all().reduce((acc, cur) => {
        acc[cur.name] = cur
        return acc
      }, {})
    },
  },

  beforeRouteLeave(to, _from, next) {
    if (!this.wasClean) {
      this.$emit("hint-unsaved", to)
      next(false)
    } else {
      next()
    }
  },

  methods: {
    translate,

    payloadFields() {
      return Object.keys(this.$v.villa).filter(key => !key.startsWith("$"))
    },

    buildPayload() {
      const payload = Utils.dup(this.villa),
            pf = this.payloadFields()
      Object.keys(payload).forEach(key => {
        if (!pf.includes(key)) {
          delete payload[key]
        }
      })
      return payload
    },

    /**
     * Mimics Rails' Record#valid? method by validating all fields (i.e.
     * marking them as invalid), and returning whether any one of them
     * failed to validate.
     */
    isValid() {
      return this.payloadFields().reduce((valid, f) => {
        const errors = this.errorsFor(f)
        if (errors.length) {
          this.$v.villa[f].$touch()
          return false
        }
        return valid
      }, true)
    },

    reset() {
      if (this.$v) {
        this.$v.$reset()
      }

      this.wasClean = true
    },

    domain(id) {
      return Domain.byID(id)
    },

    tag(id) {
      return Tag.byID(id)
    },

    category(id) {
      return Category.byID(id)
    },

    formGroupClass(attr, ...rest) {
      const a = attr.split(".").concat(rest),
            f = this._findField(a),
            r = this._remoteErrors(a).length

      return {
        "has-error":   f.$error || r > 0,
        "has-warning": !(f.$error || r > 0) && f.$dirty,
      }
    },

    errorsFor(attr, ...rest) {
      const a = attr.split(".").concat(rest),
            r = this._remoteErrors(a)
      if (r.length) {
        return r
      }

      const f = this._findField(a)
      return errorsFor("de", f)
    },

    _findField(path) {
      return path.reduce((obj, att, _i, _arr) => {
        return has(obj, att) ? obj[att] : {}
      }, this.$v.villa)
    },

    _remoteErrors(path) {
      let val = this.villa.errors

      for (let i = 0, len = path.length; i < len; ++i) {
        const cur = path[i]
        if (cur.startsWith("$")) {
          // ignore $each, $iter
          continue
        }
        if (!val[cur]) {
          // not found
          return []
        }

        val = val[cur]
      }
      return val
    },
  },
}
