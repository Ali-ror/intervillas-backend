<template>
  <div
      class="date-range-picker-calendar"
      :class="controlClasses"
  >
    <div v-if="drops" class="form-inline">
      <button
          v-if="isPosLeft"
          class="btn btn-default btn-sm mr-1"
          type="button"
          :class="canGo(-1) ? '' : 'disabled'"
          @click="go(-1)"
      >
        <i :class="icon('chevronLeft')" />
      </button>
      <DrpDropdown
          type="month"
          class="input-sm mr-1"
          :date="date"
          :min="dropdownMin"
          :max="dropdownMax || selectMax"
          @change="onDropdownChange"
      ></DrpDropdown>
      <DrpDropdown
          type="year"
          class="input-sm"
          :date="date"
          :min="dropdownMin"
          :max="dropdownMax || selectMax"
          @change="onDropdownChange"
      ></DrpDropdown>
      <button
          v-if="isPosRight"
          class="btn btn-default btn-sm ml-1"
          type="button"
          :class="canGo(1) ? '' : 'disabled'"
          @click="go(1)"
      >
        <i :class="icon('chevronRight')" />
      </button>
    </div>
    <table>
      <thead>
        <tr>
          <th v-for="(w, i) in weekdays" :key="i">
            {{ w }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(w, i) in weeks" :key="i">
          <td v-for="(day, j) in w" :key="j">
            <DrpDay
                :day="day"
                @select="$emit('select', day)"
                @cancel="$emit('cancel', day)"
                @hover="$emit('hover', day)"
            ></DrpDay>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import DrpDropdown from "./DrpDropdown.vue"
import DrpDay from "./DrpDay.vue"
import { getIcon } from "../configuration"
import {
  format,
  isAfter, isBefore,
  startOfMonth, endOfMonth,
  startOfWeek, endOfWeek,
  setHours,
  addMonths,
  setMonth,
  setYear,
} from "date-fns"
import { getLocaleData } from "../utils"

const CHANGE_DATE = {
  month: (date, val) => setMonth(date, val),
  year:  (date, val) => setYear(date, val),
}

export default {
  name: "DrpCalendar",

  components: {
    DrpDropdown,
    DrpDay,
  },

  props: {
    controls:  { type: String, required: true, validator: (val) => ["left", "right", "both", "none"].includes(val) },
    date:      { type: [Date, Number], required: true },
    min:       { type: [Date, Number], default: null },
    max:       { type: [Date, Number], default: null },
    days:      { type: Array, required: true },
    selectMax: { type: [Date, Number], default: null },
    inline:    { type: Boolean, default: false },
    splitDays: { type: Boolean, default: false },
  },

  data() {
    return {
      weekdays: getLocaleData().daysOfWeek.map(dow => dow.short),
    }
  },

  computed: {
    firstDay() {
      return setHours(startOfWeek(startOfMonth(this.date)), 12)
    },

    lastDay() {
      return setHours(endOfWeek(endOfMonth(this.date)), 12)
    },

    drops() {
      return this.controls !== "none"
    },

    isPosLeft() {
      return this.controls === "left" || this.controls === "both"
    },

    isPosRight() {
      return this.controls === "right" || this.controls === "both"
    },

    /**
     * Generiert 4-6 "Wochen" mit je 7 Tagen, jenachdem wie viele ganze Wochen in diesem einem Monat
     * liegen. Die genaue Anzahl an Wochen hängt davon ab, auf welchen Tag der Woche der 1. des
     * Monats fällt; "4 Wochen" werden nur für den Februar generiert, wenn 1.2. == Wochenanfang
     * und das Jahr kein Schaltjahr ist (28.2. == letzter Tag der 4. Woche).
     *
     * @returns {Day[][]} Tage, nach Woche gruppiert, für diesen Kalender
     */
    weeks() {
      const allWeeks = []
      let currentWeek = []

      if (![28, 35, 42].includes(this.days.length)) {
        const msg = [
          `unexpected number of days in ${format(this.date, "yyyy-MM")}, got ${this.days.length}`,
          `trailing ${this.days.length % 7} days will be ignored`,
        ]
        console.warn(msg.join("\n")) // eslint-disable-line
      }
      for (let i = 0, len = this.days.length; i < len; ++i) {
        currentWeek.push(this.days[i])

        if (i % 7 === 6) {
          allWeeks.push(currentWeek)
          currentWeek = []
        }
      }
      return allWeeks
    },

    dropdownMin() {
      if (this.min && this.controls === "right") {
        return addMonths(this.min, 1)
      }
      return this.min
    },

    dropdownMax() {
      if (this.max && this.controls === "right") {
        return addMonths(this.max, 1)
      }
      return this.max
    },

    controlClasses() {
      const { controls, inline, splitDays } = this,
            single = ["both", "none"].includes(controls) ? "col-xs-12" : "col-xs-6"

      return {
        [`controls-${controls}`]: true,
        [single]:                 true,
        inline,
        "split-days":             splitDays,
        "full-days":              !splitDays,
      }
    },
  },

  methods: {
    icon(name) {
      return getIcon(name)
    },

    go(direction) {
      if (this.canGo(direction)) {
        let date = new Date(this.date)
        if (this.controls !== "right") {
          // pos=right is already a month ahead
          date = addMonths(date, direction < 0 ? -1 : 1)
        }

        this.$emit("change", date)
      }
    },

    canGo(direction) {
      // can go to next month?
      if (direction > 0) {
        if (this.selectMax) {
          return isAfter(this.selectMax, this.lastDay)
        } else if (this.max) {
          return isAfter(this.max, this.lastDay)
        }
      }
      // can go to previous month?
      if (direction < 0 && this.min) {
        return isBefore(this.min, this.firstDay)
      }
      return true
    },

    onDropdownChange(type, val) {
      let date = CHANGE_DATE[type](new Date(this.date), val)
      if (this.controls === "right") {
        date = addMonths(date, -1)
      }

      this.$emit("change", date)
    },
  },
}
</script>
