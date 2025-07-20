<template>
  <RangePicker
      v-bind="configureDateRangePicker"
      split-days
      @change="$emit('change', $event)"
      @delete="$emit('delete')"
  >
    <template #display="{ start: arrival, end: departure }">
      <div
          v-if="arrival && departure"
          class="form-group"
          :class="{ 'has-error': errors.length > 0 }"
      >
        <span v-if="arrival && departure" class="ml-3 pull-right text-muted">
          {{ countNights(arrival, departure) }}
        </span>
        <label v-text="t('label.range')" />

        <div v-if="!inline" class="input-group">
          <span class="input-group-addon">
            <i class="fa fa-calendar" />
          </span>
          <p v-if="arrival && departure" class="form-control">
            {{ formatDate(arrival) }} – {{ formatDate(departure) }}
          </p>
        </div>

        <span
            v-for="err in errors"
            :key="err"
            class="help-block"
            v-text="err"
        />
      </div>

      <label v-else v-text="t('label.range')" />
    </template>
  </RangePicker>
</template>

<script>
import { RangePicker, Caption } from "@digineo/date-range-picker"
import { annotate, rangeSize } from "../../intervillas-drp/special-dates"
import { translate, pluralize } from "@digineo/vue-translate"
import { addDays, differenceInDays, setHours } from "date-fns"
import { formatDate, makeDate } from "../../lib/DateFormatter"

export default {
  components: {
    RangePicker,
  },

  props: {
    start:       { type: [Date, Number], default: null },
    end:         { type: [Date, Number], default: null },
    errors:      { type: Array, default: () => ([]) },
    unavailable: { type: Array, default: () => ([]) },
    inline:      { type: Boolean, default: false },
    minNights:   { type: Number, default: 7 },
  },

  computed: {
    configureDateRangePicker() {
      return {
        startDate:   this.start && this.end ? setHours(makeDate(this.start), 16) : null,
        endDate:     this.start && this.end ? setHours(makeDate(this.end), 8) : null,
        minDate:     setHours(addDays(new Date(), 1), 16),
        maxDate:     null,
        unavailable: this.unavailable,
        canDelete:   true,
        inline:      this.inline,

        captions:  [new Caption("high-season", "drp.caption.high_season")],
        rangeSize: date => rangeSize(date, this.minNights),
        rangeType: "nights",
        annotate,
      }
    },
  },

  methods: {
    t: key => translate(key, { scope: "drp" }),
    formatDate,

    countNights(arrival, departure) {
      const n = differenceInDays(departure, arrival)
      return pluralize(n, "reservation_form.nights")
    },
  },
}
</script>
