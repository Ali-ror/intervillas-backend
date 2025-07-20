<template>
  <form
      v-if="ready"
      id="reservation-form"
      class="villa-reservation-form well well-light"
      @submit.prevent="onSubmit"
  >
    <h2 class="lined-heading">
      <span v-text="t('title')" />
    </h2>

    <TeaserPrice
        v-if="!canCreateInquiry"
        :villa="villa"
        :labels="labels"
    />

    <DateRangePicker
        :start="inquiry.start_date"
        :end="inquiry.end_date"
        :errors="errorsFor('date_range')"
        :unavailable="occupancies"
        :inline="!haveDates"
        :min-nights="villa.minimum_booking_nights"
        @change="onDateSelect"
        @delete="onDateRemove"
    />

    <div v-if="haveDates">
      <div
          v-if="travelerCategories.includes('adults')"
          class="form-group"
          :class="{ 'has-error': isInvalid('adults') }"
      >
        <label for="new_inquiry_adults" class="d-flex justify-content-between align-items-center">
          {{ t('labels.adults') }}
          <abbr :title="t('hints.adults', { count: villa.beds_count })">
            <i class="fa fa-info-circle text-primary" />
          </abbr>
        </label>
        <NumericStepInput
            id="new_inquiry_adults"
            v-model.number="inquiry.adults"
            name="new_inquiry_adults"
            :min="villa.minimum_people"
            :max="maxPeople.adults"
            :max-disabled-title="t('beds_fully_occupied')"
        />
        <span
            v-for="err in errorsFor('adults')"
            :key="err"
            class="help-block"
            v-text="err"
        />
      </div>

      <div
          v-if="travelerCategories.includes('children_under_12')"
          class="form-group"
          :class="{ 'has-error': isInvalid('children_under_12') }"
      >
        <label for="new_inquiry_children_under_12" class="d-flex justify-content-between align-items-center">
          {{ t('labels.children_under_12') }}
          <abbr :title="t('hints.children_under_12')">
            <i class="fa fa-info-circle text-primary" />
          </abbr>
        </label>
        <NumericStepInput
            id="new_inquiry_children_under_12"
            v-model.number="inquiry.children_under_12"
            name="new_inquiry_children_under_12"
            min="0"
            :max="maxPeople.children_under_12"
        />
        <span
            v-for="err in errorsFor('children_under_12')"
            :key="err"
            class="help-block"
            v-text="err"
        />
      </div>

      <div
          v-if="travelerCategories.includes('children_under_6')"
          class="form-group"
          :class="{ 'has-error': isInvalid('children_under_6') }"
      >
        <label for="new_inquiry_children_under_6" class="d-flex justify-content-between align-items-center">
          {{ t('labels.children_under_6') }}
          <abbr :title="t('hints.children_under_6')">
            <i class="fa fa-info-circle text-primary" />
          </abbr>
        </label>
        <NumericStepInput
            id="new_inquiry_children_under_6"
            v-model.number="inquiry.children_under_6"
            name="new_inquiry_children_under_6"
            min="0"
            :max="maxPeople.children_under_6"
        />
        <span
            v-for="err in errorsFor('children_under_6')"
            :key="err"
            class="help-block"
            v-text="err"
        />
      </div>
    </div>

    <InquiryPrice
        v-show="haveDates"
        ref="prices"
        :villa="villa"
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

  <div v-else class="well well-light text-center">
    <i class="fa fa-fw fa-2x fa-spinner fa-pulse text-muted" />
  </div>
</template>

<script>
import DateRangePicker from "./DateRangePicker.vue"
import NumericStepInput from "./NumericStepInput.vue"
import TeaserPrice from "./TeaserPrice.vue"
import InquiryPrice from "./InquiryPrice.vue"
import { awaitSpecialDates } from "../../intervillas-drp/special-dates"
import { railsClient as api } from "../../intervillas-drp/utils"
import { has } from "../../lib/has"
import qs from "qs"
import { parseISO, format, setHours } from "date-fns"
import { makeDate } from "../../lib/DateFormatter"

import { translate } from "@digineo/vue-translate"
const t = (key, params = {}) => translate(key, { scope: "reservation_form", ...params })

export default {
  components: {
    DateRangePicker,
    NumericStepInput,
    TeaserPrice,
    InquiryPrice,
  },

  props: {
    id:  { type: Number, required: true },
    url: { type: String, required: true },
  },

  data() {
    return {
      ready:    false, // special dates loaded?
      creating: false, // inquiry request in progress?

      villa: {
        price_from:     null,
        beds_count:     null,
        weekly_pricing: null,
      },
      occupancies:        null,
      labels:             null,
      travelerCategories: [],

      inquiry: {
        villa_id:          this.id,
        start_date:        null,
        end_date:          null,
        adults:            2,
        children_under_12: 0,
        children_under_6:  0,
      },
      errors: {},
    }
  },

  computed: {
    haveDates() {
      const { start_date, end_date } = this.inquiry
      return !!start_date && !!end_date
    },

    canCreateInquiry() {
      const { haveDates, inquiry: { adults } } = this
      return haveDates && adults >= 2
    },

    maxPeople() {
      const { beds_count } = this.villa,
            { adults, children_under_12, children_under_6 } = this.inquiry
      return {
        adults:            beds_count - (children_under_12 + children_under_6),
        children_under_12: beds_count - (adults + children_under_6),
        children_under_6:  beds_count - (adults + children_under_12),
      }
    },

    currency() {
      const userSelected = document.body.dataset.currency
      if (this.villa.currencies.includes(userSelected)) {
        return userSelected
      }
      // TODO: add note à la "this Villa is priced in USD only"?
      return this.villa.currencies[0]
    },
  },

  watch: {
    inquiry: {
      deep: true,
      handler(val) {
        if (!this.ready) {
          return
        }

        const { start_date, end_date, adults, children_under_12, children_under_6 } = val
        if (start_date && end_date) {
          const params = qs.stringify({
            start_date: format(start_date, "yyyy-MM-dd"),
            end_date:   format(end_date, "yyyy-MM-dd"),
            people:     [adults, children_under_12, children_under_6],
          })
          window.history.replaceState({}, "", `${location.pathname}?${params}`)
          this.$refs.prices.fetchPrices()
        } else {
          window.history.replaceState({}, "", location.pathname)
        }
      },
    },
  },

  async mounted() {
    const [, { villa, occupancies, labels, traveler_categories }] = await Promise.all([
      awaitSpecialDates(),
      api.get(`/api/villas/${this.id}.json`).then(res => res.data),
    ])
    this.villa = Object.assign({ id: this.id }, villa)

    this.occupancies = occupancies.map(([a, b]) => ([
      setHours(parseISO(a), 16),
      setHours(parseISO(b), 8),
    ]))
    this.labels = labels
    this.travelerCategories = traveler_categories

    this._parseParams()
    await this.$nextTick()
    this.ready = true
  },

  methods: {
    t,

    _parseParams() {
      const params = qs.parse(location.search ? location.search.slice(1) : null),
            inq = Object.assign({}, this.inquiry),
            { minimum_people } = this.villa
      if (has(params, "start_date") && has(params, "end_date")) {
        Object.assign(inq, {
          start_date: setHours(makeDate(params.start_date), 16),
          end_date:   setHours(makeDate(params.end_date), 8),
        })
      }
      if (has(params, "people")) {
        const [adults, children12, children6] = params.people
        inq.adults = parseInt(adults, 10) || minimum_people
        if (this.travelerCategories.includes("children_under_12")) {
          inq.children_under_12 = parseInt(children12, 10) || 0
        }
        if (this.travelerCategories.includes("children_under_6")) {
          inq.children_under_6 = parseInt(children6, 10) || 0
        }
      }
      if (inq.adults < minimum_people) {
        inq.adults = minimum_people
      }

      this.inquiry = inq
    },

    onDateSelect([startDate, endDate]) {
      this.inquiry.start_date = startDate
      this.inquiry.end_date = endDate
      if (this.inquiry.adults < this.villa.minimum_people) {
        this.inquiry.adults = this.villa.minimum_people
      }
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

      try {
        const { start_date, end_date, adults, children_under_12, children_under_6 } = this.inquiry
        const villa_inquiry = {
          currency:   this.currency,
          start_date: format(start_date, "yyyy-MM-dd"),
          end_date:   format(end_date, "yyyy-MM-dd"),
          adults,
          children_under_12,
          children_under_6,
        }

        const { status, headers, data } = await api.post(this.url, { villa_inquiry })
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

    isInvalid(field) {
      return has(this.errors, field) && this.errors[field].length > 0
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
