<template>
  <div
      id="price_table"
      class="panel panel-default"
      :class="{ refreshing }"
  >
    <ClearingTable
        v-if="clearing"
        class="table-condensed"
        :clearing="clearing"
    />
  </div>
</template>

<script>
import ClearingTable from "./ClearingTable.vue"
import { railsClient as axios } from "../../intervillas-drp/utils"
import qs from "qs"
import { format } from "date-fns"

export default {
  components: {
    ClearingTable,
  },

  props: {
    token:    { type: String, required: true },
    inquiry:  { type: Object, required: true },
    currency: { type: String, required: true, validator: v => ["EUR", "USD"].includes(v) },
  },

  data() {
    return {
      refreshing: false,
      clearing:   null,
    }
  },

  mounted() {
    this.fetchPrices()
  },

  methods: {
    async fetchPrices() {
      const { currency, token, inquiry: { boat_id, start_date, end_date } } = this
      const params = { currency, token }
      if (boat_id && start_date && end_date) {
        params.boat = {
          boat_id,
          start_date: format(start_date, "yyyy-MM-dd"),
          end_date:   format(end_date, "yyyy-MM-dd"),
        }
      }

      try {
        this.refreshing = true
        const { data } = await axios.get("/api/inquiries/clearing.json", {
          params,
          paramsSerializer: qs.stringify,
        })

        this.clearing = data
      } finally {
        this.refreshing = false
      }
    },
  },
}
</script>
