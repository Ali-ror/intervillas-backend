<template>
  <PriceTable
      v-if="clearing"
      :value="clearing"
      :currency="currency"
      read-only
  />
</template>

<script>
import axios from "axios"
import PriceTable from "../admin/PriceTable/PriceTable.vue"

export default {
  name: "PriceTableStandalone",

  components: {
    PriceTable,
  },

  data() {
    return {
      clearing: null,
    }
  },

  computed: {
    currency() {
      const { currency } = this.clearing
      return currency
    },
  },

  async beforeMount() {
    const token = window.location.href.match("inquiries/(.*)/book")[1],
          url = `/api/inquiries/${token}.json`,
          { data } = await axios.get(url)

    this.clearing = data
  },
}
</script>
