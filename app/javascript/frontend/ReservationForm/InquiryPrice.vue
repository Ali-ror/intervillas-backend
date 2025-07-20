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
    villa:    { type: Object, required: true },
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
      const {
        currency,
        villa: { id },
        inquiry: { start_date, end_date, adults, children_under_12, children_under_6 },
      } = this

      if (!start_date || !end_date || adults < 2) {
        return
      }

      try {
        this.refreshing = true
        const { data } = await axios.get("/api/inquiries/clearing.json", {
          params: {
            currency,
            villa: {
              villa_id:   id,
              start_date: format(start_date, "yyyy-MM-dd"),
              end_date:   format(end_date, "yyyy-MM-dd"),
              adults,
              children_under_12,
              children_under_6,
            },
          },
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
