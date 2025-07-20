<template>
  <div v-text="fmtCurrency(value, currency)" />
</template>

<script>
import { currency as fmtCurrency } from "../CurrencyFormatter"

export default {
  props: {
    value:    { type: [String, Number], required: true },
    currency: { type: String, required: true },
  },

  methods: {
    fmtCurrency,
  },
}
</script>

<style scoped lang="scss">
  .small {
    font-size: 80%;
  }

  .strong {
    font-weight: bold;

    .text-muted {
      font-weight: normal;
    }
  }
</style>
