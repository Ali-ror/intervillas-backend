<template>
  <div class="admin-boat-selector">
    <RangePicker
        v-if="enabled"
        v-bind="configureDateRangePicker"
        :start-date-input-name="false"
        :end-date-input-name="false"
        @change="$emit('change', $event)"
    >
      <template #display="display">
        <div v-if="display.start && display.end" class="input-group">
          <span class="form-control">{{ formatDate(display.start) }}</span>
          <span
              class="input-group-addon"
              style="border-width:1px 0"
          >–</span>
          <span class="form-control"> {{ formatDate(display.end) }}</span>
          <span class="input-group-addon"><i class="fa fa-calendar" /></span>
        </div>
        <div v-else class="input-group">
          <span class="form-control text-muted">
            <span class="text-muted">{{ translate("drp.label.please_select") }}</span>
          </span>
          <span class="input-group-addon"><i class="fa fa-calendar" /></span>
        </div>
      </template>
    </RangePicker>

    <div v-else class="input-group">
      <span
          class="disabled form-control text-muted"
          disabled="disabled"
      >
        <span class="text-muted">{{ translate("drp.label.please_select") }}</span>
      </span>
      <span class="input-group-addon"><i class="fa fa-calendar" /></span>
    </div>
    <span
        v-if="message"
        class="help-block"
        v-text="message"
    />
  </div>
</template>

<script>
import { RangePicker, Caption, DateRange } from "@digineo/date-range-picker"
import { translate } from "@digineo/vue-translate"
import { makeDate, formatDate } from "../../lib/DateFormatter"
import { eachDayOfInterval, endOfDay, format, setHours, startOfDay } from "date-fns"

const MIN_BOAT_DAYS = 1

export default {
  components: {
    RangePicker,
  },

  props: {
    startDate: { type: [String, Date, Number], default: null },
    endDate:   { type: [String, Date, Number], default: null },
    available: { type: Array, default: null },
  },

  data() {
    return {
      enabled: false,
      message: null,
    }
  },

  computed: {
    configureDateRangePicker() {
      return {
        startDate:   this.start,
        endDate:     this.end,
        minDate:     this.available ? setHours(startOfDay(makeDate(this.available[0])), 8) : null,
        maxDate:     this.available ? setHours(endOfDay(makeDate(this.available[this.available.length - 1])), 16) : null,
        unavailable: null,
        canDelete:   false,
        inline:      false,

        captions:  [new Caption("high-season", "drp.caption.high_season")],
        rangeType: "days",
        annotate:  this.annotate,
      }
    },

    start() {
      return this.startDate ? setHours(makeDate(this.startDate), 12) : null
    },

    end() {
      return this.endDate ? setHours(makeDate(this.endDate), 12) : null
    },

    annotate() {
      return date => {
        if (this.isAvailable(date)) {
          return {}
        }
        return { blocked: true }
      }
    },
  },

  watch: {
    available() {
      this.updateRanges()
    },

    start() {
      this.updateRanges()
    },

    end() {
      this.updateRanges()
    },
  },

  mounted() {
    // Wenn neues boat_inquiry erzeugt werden soll ist das notwendig.
    this.updateRanges()
  },

  methods: {
    formatDate,
    translate,

    isAvailable(date) {
      return this.available.includes(format(date, "yyyy-MM-dd"))
    },

    updateRanges(_) {
      const dates = this.available

      if (!dates) {
        this.enabled = false
        this.message = translate("drp.boat.boat_missing")
        return
      }
      if (dates.length < MIN_BOAT_DAYS) {
        this.enabled = false
        this.message = translate("drp.boat.aleady_booked")
        return
      }

      this.message = null
      this.enabled = true

      if (!this.start && !this.end) {
        this.message = translate("drp.boat.dates_missing")
      } else {
        this.checkSelectedRange()
      }
    },

    checkSelectedRange() {
      if (!(this.start && this.end)) {
        this.message = null
        return
      }

      const { start, end } = this
      const iter = eachDayOfInterval(new DateRange(start, end)),
            invalid = iter.reduce((memo, date) => memo || !this.isAvailable(date), false)

      if (invalid) {
        // TODO: Das Speichern wird nicht verhindert! Absicht?
        this.message = translate("inquiry_editor.inquiry.boat.invalid")
      } else {
        this.message = null
      }
    },
  },
}
</script>
