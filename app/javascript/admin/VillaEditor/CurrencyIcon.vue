<template>
  <i class="fa" :class="icon" />
</template>

<script>
export default {
  name: "CurrencyIcon",

  props: {
    currency: { type: String, required: true, validator: val => ["EUR", "USD"].includes(val) },
  },

  computed: {
    icon() {
      if (this.currency === "USD") {
        return "fa-usd"
      }
      return "fa-eur"
    },
  },
}
</script>
