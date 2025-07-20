<template>
  <select
      v-model="val"
      class="form-control"
      :name="type"
      @change.prevent.stop
  >
    <option
        v-for="(item, i) in items" :key="i"
        :disabled="item.disabled"
        :selected="item.selected"
        :value="item.value"
    >
      {{ item.text }}
    </option>
  </select>
</template>

<script>
import { getMonth, getYear } from "date-fns"
import { getLocaleData } from "../utils"

export default {
  name: "DrpDropdown",

  props: {
    type: { type: String, required: true, validator: val => ["year", "month"].includes(val) },
    date: { type: [Date, Number], required: true },
    min:  { type: [Date, Number], default: null },
    max:  { type: [Date, Number], default: null },
  },

  computed: {
    val: {
      get() {
        return this.type === "year" ? getYear(this.date) : getMonth(this.date)
      },
      set(v) {
        /* do nothing, just emit a change */
        this.$emit("change", this.type, v)
      },
    },

    items() {
      let items = []

      const currentYear = getYear(this.date),
            currentMonth = getMonth(this.date),
            maxYear = this.max ? getYear(this.max) : currentYear + 5,
            minYear = this.min ? getYear(this.min) : currentYear - 100,
            inMinYear = currentYear === minYear,
            inMaxYear = currentYear === maxYear,
            monthNames = getLocaleData().monthNames.map(m => m.short)

      switch (this.type) {
      case "year":
        for (let y = maxYear; y >= minYear; --y) {
          items.push({
            value:    y,
            text:     y,
            selected: y === currentYear,
            disabled: false,
          })
        }
        break

      case "month":
        for (let m = 0; m < 12; ++m) {
          const beforeMin = this.min && inMinYear && m < getMonth(this.min),
                afterMax = this.max && inMaxYear && m > getMonth(this.max)

          items.push({
            value:    m,
            text:     monthNames[m],
            selected: m === currentMonth,
            disabled: beforeMin || afterMax,
          })
        }
        break
      }
      return items
    },
  },
}
</script>
