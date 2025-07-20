<template>
  <div>
    <h2>Belegungsstatistiken {{ villaName }}</h2>

    <div class="row">
      <div
          v-for="month in stats.months"
          :key="'table'+month.number"
          class="col-sm-6"
      >
        <table
            class="table table-bordered"
        >
          <thead>
            <tr>
              <th>{{ month.name }}</th>
              <th>{{ stats.prev_year }}</th>
              <th>{{ stats.year }}</th>
              <th>Veränderung</th>
            </tr>
          </thead>
          <tbody>
            <StatsComparisonRow
                category="Anz. Anfragen"
                :stats="month.inquiries"
            />

            <StatsComparisonRow
                category="davon Offerten"
                :nested="true"
                :stats="month.admin_inquiries"
            />

            <StatsComparisonRow
                category="Anz. Buchungen"
                :stats="month.bookings"
            />

            <StatsComparisonRow
                category="Auslastung"
                :stats="month.utilization"
                suffix="%"
            />

            <StatsComparisonRow
                category="Anz. Personen"
                :stats="month.people"
                :format="{ maximumSignificantDigits: 2 }"
            />

            <StatsComparisonRow
                category="davon Erwachsene"
                :nested="true"
                :stats="month.adults"
                :format="{ maximumSignificantDigits: 2 }"
            />

            <StatsComparisonRow
                category="davon Kinder bis 12"
                :nested="true"
                :stats="month.children_under_12"
                :format="{ maximumSignificantDigits: 2 }"
            />

            <StatsComparisonRow
                category="davon Kinder bis 6"
                :nested="true"
                :stats="month.children_under_6"
                :format="{ maximumSignificantDigits: 2 }"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import Utils from "../../intervillas-drp/utils"
import CurrencyFormatter from "../CurrencyFormatter"
import StatsComparisonRow from "./StatsComparisonRow.vue"

export default {
  name: "StatsComparisonShow",

  components: {
    StatsComparisonRow,
  },

  mixins: [
    CurrencyFormatter,
  ],

  props: {
    villaParam: { type: String, required: true },
    villaName:  { type: String, required: true },
    year:       { type: [Number, String], required: true },
  },
  data() {
    return {
      stats: [],
    }
  },
  watch: {
    villaParam: "fetchData",
    year:       "fetchData",
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      Utils.fetchJSON(`/api/admin/stats/${this.villaParam}/${this.year}`)
        .then(data => this.stats = data)
    },
    sign(number) {
      if (number > 0) {
        return "+"
      }
    },
  },
}
</script>
