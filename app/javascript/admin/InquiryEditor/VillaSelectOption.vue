<template>
  <div v-if="!id" v-text="label" />
  <div v-else class="d-flex flex-grow-1 justify-content-between align-items-baseline gap-3">
    <span v-text="label" />

    <span class="ml-auto text-muted small">
      {{ currencyText }}
    </span>
  </div>
</template>

<script>
export default {
  props: {
    id:    { type: [String, Number], default: null },
    label: { type: String, required: true },
    eur:   { type: Boolean, default: false },
    usd:   { type: Boolean, default: false },
  },

  computed: {
    currencyText() {
      const { eur, usd } = this
      if (eur && !usd) {
        return "EUR (+ USD)"
      }
      if (!eur && usd) {
        return "USD-only"
      }
      if (eur && usd) {
        return "EUR + USD"
      }
      return "—"
    },
  },
}
</script>
