<template>
  <div class="input-group">
    <span class="input-group-addon">
      <i class="fa" :class="`fa-${currency.toLowerCase()}`" />
    </span>
    <label
        class="sr-only"
        :for="formId"
        v-text="price.abel"
    />
    <input
        :id="formId"
        v-model.number="priceValue"
        :placeholder="`${price.label} (${currency})`"
        :disabled="price.destroy"
        :required="required"
        type="number"
        class="form-control"
        min="0"
        step="0.01"
    >
    <span v-if="!price.destroy" class="input-group-btn">
      <button
          v-if="converted"
          type="button"
          class="btn btn-default"
          title="automatisch umgerechnet"
          @click="price.set(currency, converted)"
      >
        {{ converted | currency(currency) }}
      </button>
      <button
          v-else-if="currency !== 'EUR'"
          type="button"
          class="btn btn-default"
          @click="price.set(currency, null)"
      >
        <i class="fa fa-times" />
      </button>
    </span>
  </div>
</template>

<script>
import CurrencyFormatter from "../CurrencyFormatter"
import { Price } from "./models"

export default {
  mixins: [CurrencyFormatter],

  props: {
    value:        { type: Price, default: null }, // v-model
    currency:     { type: String, required: true, validator: val => ["EUR", "USD"].includes(val) },
    exchangeRate: { type: Number, default: null },
    required:     { type: Boolean, default: false },
  },

  computed: {
    price: {
      get() {
        return this.value
      },
      set(val) {
        this.$emit("input", val)
      },
    },

    priceValue: {
      get() {
        return this.price.get(this.currency)
      },
      set(val) {
        this.price.set(this.currency, val)
      },
    },

    formId() {
      const { price, currency } = this,
            id = ["boat_price", currency.toLowerCase()]

      if (price.category === "daily") {
        id.push("daily", price.days)
      } else {
        id.push(price.category)
      }
      return id.join("_")
    },

    converted() {
      const { price, currency, exchangeRate } = this
      if (exchangeRate) {
        return price.convertTo(currency, exchangeRate)
      }
      return null
    },
  },
}
</script>
