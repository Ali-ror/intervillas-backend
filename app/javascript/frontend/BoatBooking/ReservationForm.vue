<template>
  <form
      id="reservation-form"
      class="boat-reservation-form well well-light"
      @submit.prevent="onSubmit"
  >
    <h2 class="lined-heading">
      <span v-text="t('title')" />
    </h2>

    <div class="form-group">
      <span class="ml-3 pull-right text-muted" v-text="bookingNights" />
      <label v-text="t('label.range', { scope: 'drp' })" />
      <div class="input-group">
        <span class="input-group-addon">
          <i class="fa fa-calendar" />
        </span>
        <p class="form-control" disabled>
          {{ formatDate(arrival) }} – {{ formatDate(departure) }}
        </p>
      </div>
    </div>

    <DateRangePicker
        v-if="boat"
        :arrival="arrival"
        :departure="departure"
        :min-days="boat.minimum_days"
        :errors="errorsFor('date_range')"
        :unavailable="boat.occupancies"
        :inline="!haveDates"
        @change="onDateSelect"
        @delete="onDateRemove"
    />

    <InquiryPrice
        ref="prices"
        :token="token"
        :inquiry="inquiry"
        :currency="currency"
    />

    <button
        type="submit"
        class="btn btn-block btn-primary"
        :disabled="!canCreateInquiry || creating"
    >
      {{ t('new_inquiry') }}
      <i v-if="creating" class="fa fa-spinner fa-pulse" />
    </button>
  </form>
</template>

<script>
import DateRangePicker from "./DateRangePicker.vue"
import InquiryPrice from "./InquiryPrice.vue"
import { railsClient as api } from "../../intervillas-drp/utils"
import { has } from "../../lib/has"
import { formatDate } from "../../lib/DateFormatter"
import { translate, pluralize } from "@digineo/vue-translate"
import { differenceInDays, format } from "date-fns"

export default {
  components: {
    DateRangePicker,
    InquiryPrice,
  },

  props: {
    boat:      { type: Object, default: null },
    arrival:   { type: [Date, Number], required: true },
    departure: { type: [Date, Number], required: true },
    token:     { type: String, required: true },
    currency:  { type: String, required: true, validate: val => ["EUR", "USD"].includes(val) },
  },

  data() {
    return {
      creating: false, // inquiry request in progress?
      errors:   {},

      inquiry: {
        boat_id:    this.boat?.id,
        start_date: null,
        end_date:   null,
      },
    }
  },

  computed: {
    haveDates() {
      const { start_date, end_date } = this.inquiry
      return !!start_date && !!end_date
    },

    canCreateInquiry() {
      const { haveDates, inquiry: { boat_id } } = this
      return haveDates && boat_id
    },

    bookingNights() {
      const n = differenceInDays(this.departure, this.arrival) + 1
      return pluralize(n, "reservation_form.nights")
    },
  },

  watch: {
    boat(boat) {
      if (boat) {
        this.inquiry.boat_id = boat.id
        return
      }

      this.inquiry = {
        boat_id:    null,
        start_date: null,
        end_date:   null,
      }
    },

    inquiry: {
      deep: true,
      handler() {
        this.$refs.prices.fetchPrices()
      },
    },
  },

  methods: {
    t: (key, params = {}) => translate(key, { scope: "reservation_form", ...params }),
    pluralize,
    formatDate,

    onDateSelect([startDate, endDate]) {
      this.inquiry.start_date = startDate
      this.inquiry.end_date = endDate
    },

    onDateRemove() {
      this.inquiry.start_date = null
      this.inquiry.end_date = null
    },

    async onSubmit() {
      if (!this.canCreateInquiry || this.creating) {
        return
      }

      this.creating = true
      this.errors = {}

      const { token, inquiry: { boat_id, start_date, end_date } } = this,
            url = `/inquiries/${token}/boat`

      const boat_inquiry = {
        boat_id,
        start_date: format(start_date, "yyyy-MM-dd"),
        end_date:   format(end_date, "yyyy-MM-dd"),
      }
      try {
        const { status, headers, data } = await api.patch(url, { boat_inquiry })
        switch (status) {
        case 201:
          window.location.replace(headers.location)
          return
        case 422:
          this.errors = data
          return
        }
      } finally {
        this.creating = false
      }
    },

    errorsFor(field) {
      return has(this.errors, field) ? this.errors[field] : []
    },
  },
}
</script>

<style lang="scss" scoped>
  h2.lined-heading {
    font-size: 16px;
  }
</style>
