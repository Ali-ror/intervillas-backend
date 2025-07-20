<template>
  <div class="input-group">
    <input
        v-model="model"
        type="text"
        class="text-right form-control"
    >
    <div v-if="showDropDown" class="input-group-btn">
      <button
          :class="dropdownClasses"
          data-toggle="dropdown"
          :title="t('has_normal_price')"
      >
        <i class="fa fa-caret-down" />
      </button>
      <ul class="dropdown-menu dropdown-menu-right">
        <li class="text-right">
          <a
              href="#"
              @click.prevent="$emit('input', normalPrice)"
              v-text="t('apply_normal_price', { price: fmtCurrency(normalPrice, currency) })"
          />
        </li>
      </ul>
    </div>
    <span
        v-else
        class="input-group-addon"
        v-text="currency === 'USD' ? '$' : '€'"
    />
  </div>
</template>

<script>
import { currency as fmtCurrency } from "../CurrencyFormatter"
import { translate } from "@digineo/vue-translate"
const t = (key, params = {}) => translate(key, { scope: "price_table", ...params })

export default {
  props: {
    value:         { type: Number, required: true },
    currency:      { type: String, required: true },
    forceNegative: { type: Boolean, default: false },
    normalPrice:   { type: Number, default: null },
  },

  computed: {
    isNormalPrice() {
      return this.normalPrice === this.value
    },

    dropdownClasses() {
      return {
        "btn":             true,
        "btn-warning":     !this.isNormalPrice,
        "btn-default":     this.isNormalPrice,
        "dropdown-toggle": true,
      }
    },

    showDropDown() {
      return this.normalPrice && !this.isNormalPrice
    },

    model: {
      get() {
        return this.value
      },

      set(value) {
        if (value === "" || value === "-") {
          value = 0 // common case
        }

        let number = Number(value)
        if (isNaN(number)) {
          return // reject invalid input
        }
        if (this.forceNegative && number > 0) {
          number *= -1
        }

        this.$emit("input", number)
      },
    },

  },

  methods: {
    t,
    fmtCurrency,
  },
}
</script>
