<template>
  <RangePicker
      v-bind="configureDateRangePicker"
      @change="$emit('change', $event)"
      @delete="$emit('delete')"
  >
    <template #display="{ start, end }">
      <div
          v-if="start && end"
          class="form-group"
          :class="{ 'has-error': errors.length }"
      >
        <span v-if="start && end" class="ml-3 pull-right text-muted">
          {{ countDays(start, end) }}
        </span>
        <label v-text="t('label.rental_period')" />

        <div v-if="!inline" class="input-group">
          <span class="input-group-addon">
            <i class="fa fa-calendar" />
          </span>
          <p v-if="start && end" class="form-control">
            {{ formatDate(start) }} – {{ formatDate(end) }}
          </p>
        </div>

        <span
            v-for="err in errors"
            :key="err"
            class="help-block"
            v-text="err"
        />
      </div>

      <label v-else v-text="t('label.rental_period')" />
    </template>
  </RangePicker>
</template>

<script>
import { RangePicker, Caption } from "@digineo/date-range-picker"
import { annotate } from "../../intervillas-drp/special-dates"
import { translate, pluralize } from "@digineo/vue-translate"
import { addDays, differenceInDays, setHours } from "date-fns"
import { formatDate } from "../../lib/DateFormatter"

export default {
  components: {
    RangePicker,
  },

  props: {
    arrival:     { type: [Date, Number], default: null },
    departure:   { type: [Date, Number], default: null },
    errors:      { type: Array, default: () => ([]) },
    unavailable: { type: Array, default: () => ([]) },
    inline:      { type: Boolean, default: false },
    minDays:     { type: Number, default: 3 },
  },

  computed: {
    configureDateRangePicker() {
      return {
        startDate:   null,
        endDate:     null,
        minDate:     this.arrival ? setHours(addDays(this.arrival, 1), 8) : null,
        maxDate:     this.departure ? setHours(addDays(this.departure, -1), 16) : null,
        unavailable: this.unavailable,
        canDelete:   true,
        inline:      this.inline,

        captions:  [new Caption("high-season", "drp.caption.high_season")],
        rangeSize: () => this.minDays - 1,
        rangeType: "days",
        annotate,
      }
    },
  },

  methods: {
    formatDate,
    t: key => translate(key, { scope: "drp" }),

    countDays(arrival, departure) {
      const n = differenceInDays(departure, arrival) + 1
      return pluralize(n, "reservation_form.days")
    },
  },
}
</script>
