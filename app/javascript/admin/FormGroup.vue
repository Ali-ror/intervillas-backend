<template>
  <div class="form-group" :class="{ 'has-error': hasError }">
    <label class="control-label col-sm-4" :for="domID">
      {{ labelText }}

      <svg
          v-if="isRequired"
          height="10"
          width="10"
      >
        <path
            fill="#ff9900"
            stroke="none"
            d="M7.5 0v10l-5 -5z"
        />
      </svg>
    </label>

    <div class="col-sm-8">
      <UiSelect
          v-if="inferredType === 'ui-select'"
          :id="domID"
          v-model="value"
          clearable
          placeholder="Bitte wählen"
          :options="collectionOptions"
      />

      <div v-if="inferredType === 'slot'" :id="domID">
        <slot />
      </div>

      <div v-if="inferredType === 'number'" class="input-group">
        <input
            :id="domID"
            v-model="value"
            class="form-control"
            type="number"
            :step="stepVal"
            :min="minVal"
        >
        <span class="input-group-btn">
          <button
              class="btn"
              :class="hasError ? 'btn-danger' : 'btn-default'"
              type="button"
              @click="addToValue(stepVal)"
          ><i class="fa fa-plus" /></button>
          <button
              class="btn"
              :class="hasError ? 'btn-danger' : 'btn-default'"
              type="button"
              @click="addToValue(-stepVal)"
          ><i class="fa fa-minus" /></button>
        </span>
      </div>

      <input
          v-if="inferredType === 'string' || inferredType === 'email'"
          :id="domID"
          v-model.trim="value"
          class="form-control"
          type="text"
      >

      <select
          v-if="inferredType === 'select'"
          :id="domID"
          v-model="value"
          class="form-control"
      >
        <option
            v-for="(v,k) of collectionOptions"
            :key="k"
            :value="k"
            v-text="v"
        />
      </select>

      <span v-if="hasError" class="help-block">
        {{ errorMessages.join(", ") }}
      </span>
    </div>
  </div>
</template>

<script>
import UiSelect from "../components/UiSelect.vue"
import { Base as Model } from "./models/model"

const SUPPORTED_TYPES = Object.freeze([
  "string", "email", // input[type=text]
  "select", // select > option*n
  "ui-select", // UiSelect
  "slot", // pass-through
  "number", // input[type=number]
])

const HEX_CHARS = "0123456789abcdef"

const randomID = function(prefix) {
  const result = [],
        uid = []

  if (prefix) {
    result.push(prefix)
  }
  for (let i = 0; i < 8; ++i) {
    const char_index = Math.floor(Math.random() * 16),
          char = HEX_CHARS.charAt(char_index)
    uid.push(char)
  }

  result.push(uid.join(""))
  result.push(btoa(Date.now()).replace(/[+/=]/g, str => {
    return str === "+" ? "-" : str === "/" ? "_" : ""
  }))

  return result.join("-")
}

export default {
  name: "FormGroup",

  components: {
    UiSelect,
  },

  props: {
    model: { type: Model, required: true },
    field: { type: String, required: true },
    label: { type: String, default: null },

    type: { type: String, default: null, validator: v => SUPPORTED_TYPES.includes(v) },

    collection: { type: undefined, default: null }, // for type=select, ui-select
    min:        { type: [String, Number], default: null }, // for type=number
    max:        { type: [String, Number], default: null }, // for type=number
    step:       { type: [String, Number], default: null }, // for type=number
  },

  data() {
    const attribute = this.model.getField(this.field)
    return {
      labelText: this.label || attribute.label,
      value:     attribute.get(),
      domID:     randomID(attribute.name),
      attribute,
    }
  },

  computed: {
    collectionOptions() {
      if (this.collection) {
        return this.collection
      }
      if (this.attribute.constraints.inclusion) {
        return this.attribute.constraints.inclusion.within
      }
      return null
    },

    inferredType() {
      if (this.type) {
        return this.type
      }

      const c = this.attribute.constraints
      if (c.inclusion) {
        return "select"
      }
      if (c.email) {
        return "email"
      }
      if (c.numericality) {
        return "number"
      }
      return "string"
    },

    minVal() {
      if (this.min) {
        const min = parseFloat(this.min)
        if (!isNaN(min)) {
          return min
        }
      }

      const num = this.attribute.constraints.numericality
      if (num) {
        if ("greaterThanOrEqualTo" in num) {
          return num.greaterThanOrEqualTo
        }
        if ("greaterThan" in num) {
          return num.greaterThan + 1
        }
      }
      return null
    },

    maxVal() {
      if (this.max) {
        const max = parseFloat(this.max)
        if (!isNaN(max)) {
          return max
        }
      }

      const num = this.attribute.constraints.numericality
      if (num) {
        if ("lessThanOrEqualTo" in num) {
          return num.lessThanOrEqualTo
        }
        if ("lessThan" in num) {
          return num.lessThan
        }
      }
      return null
    },

    stepVal() {
      if (this.step) {
        const step = parseFloat(this.step)
        if (!isNaN(step)) {
          return step
        }
      }

      const num = this.attribute.constraints.numericality
      if (num && num.onlyInteger) {
        return 1
      }
      return null
    },

    isRequired() {
      return this.attribute.constraints.presence
    },

    hasError() {
      return this.attribute.dirty && this.attribute.errors().length > 0
    },

    errorMessages() {
      return this.attribute.dirty && this.attribute.errors()
    },
  },

  watch: {
    value(val) {
      this.attribute.set(val)
      this.$emit("change", val)
    },
  },

  methods: {
    addToValue(amount) {
      let curr = Number.isFinite(this.value) ? this.value + amount : amount

      if (Number.isFinite(this.minVal) && curr < this.minVal) {
        curr = this.minVal
      }
      if (Number.isFinite(this.maxVal) && curr > this.maxVal) {
        curr = this.maxVal
      }

      this.value = curr
    },
  },
}
</script>
