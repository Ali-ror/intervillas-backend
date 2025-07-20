<template>
  <div v-if="inquiry" class="panel panel-primary">
    <div class="panel-heading">
      {{ t("label") }}
      <span class="pull-right">IV-{{ inquiry.external ? "E" : "" }}{{ inquiry.id }}</span>
    </div>

    <div class="panel-body pb-0">
      <h3>{{ t("inquiry.label") }}</h3>
      <dl>
        <dt>{{ t("inquiry.created_at") }}</dt>
        <dd>{{ formatDateTime(inquiry.created_at) }}</dd>
        <template v-if="booked_at">
          <dt>{{ t("inquiry.updated_at") }}</dt>
          <dd>{{ formatDateTime(inquiry.booking_updated_at) }}</dd>
          <dt>{{ t("inquiry.booked_at") }}</dt>
          <dd>{{ formatDateTime(booked_at) }}</dd>
        </template>
        <template v-if="cancelled_at">
          <dt>{{ t("inquiry.cancelled_at") }}</dt>
          <dd>{{ formatDateTime(cancelled_at) }}</dd>
        </template>

        <dt>{{ t("traveler.label") }}</dt>
        <dd>
          <ul class="my-0">
            <li v-for="traveler in inquiry.villa_inquiry.travelers" :key="traveler.id">
              <template v-if="traveler.first_name || traveler.last_name">
                {{ traveler.first_name }} {{ traveler.last_name }}
              </template>
              <em v-else class="text-muted">
                {{ t("traveler.unknown") }}
              </em>
              <template v-if="traveler.born_on">
                ({{ t("traveler.born") }} {{ formatDate(traveler.born_on) }})
                <i
                    v-if="hasBirthday(traveler)"
                    :title="t('traveler.birthday')"
                    class="fa fa-fw fa-birthday-cake text-muted"
                />
              </template>
            </li>
          </ul>
        </dd>

        <dt>{{ t("travel_insurance.label") }}</dt>
        <dd v-text="t(`travel_insurance.${inquiry.travel_insurance}`)"/>
      </dl>
    </div>

    <div class="panel-body pt-3 pb-0 details-villa">
      <h3>{{ t("bookable.villa") }}</h3>
      <dl>
        <dt>{{ t("bookable.villa") }}</dt>
        <dd>
          <a :href="inquiry.villa_inquiry.public_villa_path">
            {{ inquiry.villa_inquiry.villa_name }}
          </a>
        </dd>

        <dt>{{ t("bookable.dates") }}</dt>
        <dd>{{ formatDateRange(inquiry.villa_inquiry) }}</dd>
        <dd class="days text-muted small">
          {{ pluralize(inquiry.villa_inquiry.nights, "shared.discount.nights_count") }}
        </dd>

        <dt>{{ t("bookable.discounts") }}</dt>
        <dd>
          <DiscountsTable
              :read-only="readOnly"
              :discounts="villaDiscounts"
              @edit="editDiscount"
          />
        </dd>
      </dl>
    </div>

    <div v-if="validBoatInquiry" class="panel-body pt-3 details-boat">
      <h3>{{ t("bookable.boat") }}</h3>
      <dl>
        <dt>{{ t("bookable.boat") }}</dt>
        <dd>{{ inquiry.boat_inquiry.name }}</dd>
        <dt>{{ t("bookable.dates") }}</dt>
        <dd>{{ formatDateRange(inquiry.boat_inquiry) }}</dd>
        <dd class="days text-muted small">
          {{ pluralize(inquiry.boat_inquiry.days, "shared.discount.days_count") }}
        </dd>

        <dt>{{ t("bookable.discounts") }}</dt>
        <dd>
          <DiscountsTable
              :discounts="boatDiscounts"
              :read-only="readOnly"
              @edit="editDiscount"
          />
        </dd>
      </dl>
    </div>

    <EditDiscountModal
        ref="editDiscountModal"
        :dates="travelerDateRange"
        :villa-id="inquiry.villa_inquiry.villa_id"
        @change-discount="updateDiscount"
    />
  </div>
</template>

<script>
import { translate, pluralize } from "@digineo/vue-translate"
import {
  formatDate,
  formatDateRange,
  formatDateTime,
  makeDate,
} from "../../../lib/DateFormatter"
import DiscountsTable from "./DiscountsTable.vue"
import EditDiscountModal from "./EditDiscount.vue"
import { Discount } from "./discount"
import { endOfDay, format, getYear, isAfter, isBefore, setHours, setYear, startOfDay } from "date-fns"

function emptyDiscounts(inquiry_kind, inquiry_id) {
  let subjects = translate("shared.discount.subjects")
  return Object.keys(subjects).reduce((discounts, subject) => {
    discounts[subject] = new Discount({ inquiry_id, inquiry_kind, subject })
    return discounts
  }, {})
}

const t = key => translate(key, { scope: "inquiry_editor.sidebar" })

export default {
  name: "SidebarDetails",

  components: {
    DiscountsTable,
    EditDiscountModal,
  },

  props: {
    readOnly: { type: Boolean, default: false },
  },

  data() {
    return {
      booked_at:    null,
      cancelled_at: null,
      inquiry:      null,
    }
  },

  computed: {
    travelerDateRange() {
      const [start_date, end_date] = this.inquiry.villa_inquiry.travelers.slice(1).reduce(([min, max], t) => {
        const start = makeDate(t.start_date),
              end = makeDate(t.end_date)
        return [
          min && isBefore(min, start) ? min : start,
          max && isAfter(max, end) ? max : end,
        ]
      }, [null, null])

      return { start_date, end_date }
    },

    villaDiscounts() {
      return this.inquiry.villa_inquiry.discounts.reduce((group, discount) => {
        group[discount.subject].copyFrom(discount)
        return group
      }, emptyDiscounts("villa", this.inquiry.id))
    },

    boatDiscounts() {
      const collection = this.inquiry.boat_inquiry
        ? this.inquiry.boat_inquiry.discounts
        : []
      return collection.reduce((group, discount) => {
        group[discount.subject].copyFrom(discount)
        return group
      }, emptyDiscounts("boat", this.inquiry.id))
    },

    validBoatInquiry() {
      return this.inquiry.boat_inquiry
        && this.inquiry.boat_inquiry.boat_id
        && this.inquiry.boat_inquiry.start_date
        && this.inquiry.boat_inquiry.end_date
    },
  },

  mounted() {
    window.sidebarDetails = this
  },

  methods: {
    formatDateTime,
    formatDate,
    formatDateRange,
    pluralize,
    t,

    setInquiry(data) {
      this.inquiry = data
      this.booked_at = data.booked_at
      this.cancelled_at = data.cancelled_at
    },

    hasBirthday({ start_date, end_date, born_on }) {
      const s = startOfDay(makeDate(start_date)),
            e = endOfDay(makeDate(end_date)),
            b = setYear(setHours(makeDate(born_on), 12), getYear(s))
      return isBefore(s, b) && isBefore(b, e)
    },

    editDiscount(discount) {
      this.$refs.editDiscountModal.show(discount)
    },

    updateDiscount({ inquiry_kind, subject, start_date, end_date, value }) {
      const collection = this.inquiry[`${inquiry_kind}_inquiry`]
      if (!collection) {
        return
      }

      const idx = collection.discounts.findIndex(d => d.subject === subject)
      if (idx >= 0 && value) {
        // update existing discount
        const discount = collection.discounts[idx]
        discount.value = value
        discount.start_date = format(start_date, "yyyy-MM-dd")
        discount.end_date = format(end_date, "yyyy-MM-dd")
      } else if (idx >= 0) {
        // no value = remove existing discount
        collection.discounts.splice(idx, 1)
      } else {
        // neither value, nor index: create new entry
        collection.discounts.push({
          subject,
          value,
          start_date: format(start_date, "yyyy-MM-dd"),
          end_date:   format(end_date, "yyyy-MM-dd"),
        })
      }
    },
  },
}
</script>

<style scoped>
  dd {
    margin-left: 30px;
  }
  dd table {
    margin-bottom: 0;
  }
</style>
