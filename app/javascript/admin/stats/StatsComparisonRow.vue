<template>
  <tr>
    <td>
      <span v-if="nested">-</span>
      {{ category }}
    </td>
    <td>{{ stats.prev_year | conditionalFormat(format) }}{{ suffix }}</td>
    <td>{{ stats.year | conditionalFormat(format) }}{{ suffix }}</td>
    <td :class="changeClasses">
      {{ stats.change | conditionalFormat(format) | sign }}{{ suffix }}
    </td>
  </tr>
</template>

<script>
import NumberFormatter from "../NumberFormatter"

export default {
  name:    "StatsComparisonRow",
  filters: {
    sign(number) {
      if (number > 0) {
        return "+" + number
      }
      return number
    },
    conditionalFormat(val, format) {
      if (!format) {
        return val
      }
      return NumberFormatter.filters.numberFormat(val, format)
    },
  },
  props: {
    stats:    { type: Object, required: true },
    category: { type: String, required: true },
    nested:   { type: Boolean, default: false },
    suffix:   { type: String, default: "" },
    format:   { type: Object },
  },
  computed: {
    changeClasses() {
      return { "text-success": this.stats.change > 0, "text-danger": this.stats.change < 0 }
    },
  },
}
</script>
