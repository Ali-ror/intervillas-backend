<template>
  <div class="row">
    <div class="col-sm-12">
      <h1>
        Umsatzanalyse
        <template v-if="date">
          {{ prevYear }}/{{ year }} bis {{ format(date, "d. MMMM") }}
        </template>
      </h1>
    </div>

    <SinglePicker
        class="col-sm-6 col-sm-push-3 mt-3"
        @change="date = $event[0]"
    >
      <template #display="display">
        <div class="input-group">
          <span v-if="display.start" class="form-control">
            {{ formatDate(display.start) }}
          </span>
          <span v-else class="form-control">
            <span class="text-muted">
              Bitte das Datum auswählen, bis zu dem die Auswertung durchgeführt werden soll.
            </span>
          </span>
          <span class="input-group-addon">
            <i class="fa fa-calendar" />
          </span>
        </div>
      </template>
    </SinglePicker>

    <div class="col-sm-8 col-sm-push-2 mt-5">
      <Loading v-if="loading"/>
      <table v-else-if="sales" class="table table-bordered">
        <thead>
          <tr>
            <th>{{ dateRange }}</th>
            <th>{{ prevYear }}</th>
            <th>{{ year }}</th>
            <th>Veränderung</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="cur in currencies" :key="`brutto_${cur}`">
            <td>Brutto {{ cur }}</td>
            <td>{{ sales.prev_year[cur] | currency(cur) }}</td>
            <td>{{ sales.year[cur] | currency(cur) }}</td>
            <td :class="{ 'text-success': sales.change[cur] > 0, 'text-danger': sales.change[cur] < 0 }">
              {{ sales.change[cur] | currency(cur) }}
            </td>
          </tr>
          <tr v-for="cur in currencies" :key="`netto_${cur}`">
            <td>Netto {{ cur }}</td>
            <td>{{ sales.prev_year_net[cur] | currency(cur) }}</td>
            <td>{{ sales.year_net[cur] | currency(cur) }}</td>
            <td :class="{ 'text-success': sales.change_net[cur] > 0, 'text-danger': sales.change_net[cur] < 0 }">
              {{ sales.change_net[cur] | currency(cur) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import { SinglePicker } from "@digineo/date-range-picker"
import Utils from "../intervillas-drp/utils"
import CurrencyFormatter from "./CurrencyFormatter"
import Loading from "./Loading.vue"
import { formatDate } from "../lib/DateFormatter"
import { format, formatISO } from "date-fns"

export default {
  name: "AdminSales",

  components: {
    SinglePicker,
    Loading,
  },

  mixins: [
    CurrencyFormatter,
  ],

  data() {
    return {
      date:       null,
      sales:      null,
      loading:    false,
      currencies: ["EUR", "USD"],
    }
  },

  computed: {
    year() {
      return this.date.getFullYear()
    },

    prevYear() {
      return this.year - 1
    },

    dateRange() {
      return `1. Jan. - ${format(this.date, "d. MMM")}`
    },

    isoDate() {
      return formatISO(this.date, { represenation: "date" })
    },
  },

  watch: {
    date(newDate) {
      if (!newDate) {
        return
      }

      this.loading = true
      this.sales = null
      Utils.fetchJSON(`/api/admin/sales?date=${this.isoDate}`).then(data => {
        this.loading = false
        this.sales = data
        return
      })
    },
  },

  methods: {
    formatDate,
    format,
  },
}
</script>

<style scoped>
  table {
    margin-top: 9px;
  }
</style>
