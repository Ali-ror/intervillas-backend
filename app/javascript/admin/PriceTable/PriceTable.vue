<template>
  <div class="js-price-table">
    <div
        v-if="error"
        class="alert alert-danger"
        :class="{ hidden: !error }"
        v-text="error"
    />

    <div
        v-else
        class="panel panel-primary"
        :class="{ hidden: !clearing.total }"
    >
      <div class="panel-heading">
        {{ t('heading') }} in {{ currency }}
      </div>

      <table
          id="price_table"
          class="table table-striped table-condensed"
          :class="{ refreshing }"
      >
        <thead>
          <tr>
            <th v-if="!readOnly" v-text="t('dates')" />
            <th class="text-right">
              {{ (!readOnly || null) && ['nights.other', 'days.other'].map(t).join('/') }}
            </th>
            <th class="text-right">
              {{ (!readOnly || null) && t("num_people") }}
            </th>
            <th v-text="t('category')" />
            <th
                class="text-right"
                :width="readOnly ? null : '120px'"
                v-text="t('price')"
            />
            <th
                class="text-right"
                :width="readOnly ? null : '140px'"
                v-text="t('total')"
            />
          </tr>
        </thead>

        <tbody v-for="(rentable_clearing, i) in clearing.rentable_clearings" :key="i">
          <tr
              v-for="ci in active_clearing_items(rentable_clearing.rents)"
              :key="ci.id"
              :title="clearingItemTitle(ci)"
          >
            <td v-if="!readOnly" v-text="period(ci.period)" />
            <td class="text-right" v-text="ci.human_time_units" />
            <td class="text-right" v-text="isBaseRate(ci.category) ? '' : ci.amount" />
            <td v-text="ci.human_category" />
            <td class="text-right">
              <Component
                  :is="readOnly ? 'PriceDisplay' : 'PriceInput'"
                  v-model="ci.price.value"
                  :currency="ci.price.currency"
                  :normal-price="ci.normal_price"
                  @input="refreshTotal(ci)"
              />
            </td>
            <td class="text-right">
              <PriceDisplay
                  v-model="ci.total.value"
                  :currency="ci.total.currency"
              />
            </td>
          </tr>
        </tbody>

        <tbody>
          <tr v-if="!readOnly" class="top-rule">
            <td :colspan="readOnly ? 2 : 3" />
            <td colspan="2">
              <strong v-text="t('sub_total')" />
            </td>
            <td class="text-right">
              <PriceDisplay
                  v-model="clearing.total_rents.value"
                  :currency="clearing.total_rents.currency"
                  class="strong"
              />
            </td>
          </tr>

          <tr v-for="ci in other_clearing_items" :key="ci.id">
            <td :colspan="readOnly ? 2 : 3" />
            <td colspan="2">
              <Component :is="ci._destroy ? 's' : 'span'">
                {{ ci.human_category }}
              </Component>
              <div
                  v-if="showNoteInput(ci)"
                  class="d-flex justify-content-between align-items-baseline gap-2"
              >
                <NoteInput
                    v-if="!ci._destroy"
                    v-model="ci.note"
                />
                <DestroyClearingItem
                    v-model="ci._destroy"
                    class="ml-auto"
                />
              </div>
            </td>
            <td class="text-right">
              <s v-if="ci._destroy">
                {{ fmtCurrency(ci.price.value, ci.price.currency) }}
              </s>
              <Component
                  :is="readOnly ? 'PriceDisplay' : 'PriceInput'"
                  v-else
                  v-model="ci.price.value"
                  :currency="ci.price.currency"
                  :normal-price="ci.normal_price"
                  :force-negative="ci.category.endsWith('discount')"
                  @input="refreshTotal(ci)"
              />
            </td>
          </tr>

          <tr class="rule-bold">
            <td :colspan="readOnly ? 2 : 3" />
            <td colspan="2">
              <strong v-text="t('rental_price')" />
            </td>
            <td class="text-right">
              <PriceDisplay
                  v-if="clearing.sub_total"
                  v-model="clearing.sub_total.value"
                  :currency="clearing.sub_total.currency"
                  class="strong"
              />
            </td>
          </tr>

          <tr v-for="clearing_item in clearing.deposits" :key="clearing_item.id">
            <td :colspan="readOnly ? 2 : 3" />
            <td colspan="2" v-text="clearing_item.human_category" />
            <td class="text-right">
              <Component
                  :is="readOnly ? 'PriceDisplay' : 'PriceInput'"
                  v-model="clearing_item.price.value"
                  :currency="clearing_item.price.currency"
                  :normal-price="clearing_item.normal_price"
                  @input="refreshTotal(clearing_item)"
              />
            </td>
          </tr>
        </tbody>

        <tbody>
          <tr class="top-rule">
            <td :colspan="readOnly ? 2 : 3" />
            <td colspan="2" v-text="t('rental_price_including')" />
            <td class="text-right">
              <PriceDisplay
                  v-if="clearing.total"
                  v-model="clearing.total.value"
                  :currency="clearing.total.currency"
              />
            </td>
          </tr>

          <slot name="at-end-of-table" />
        </tbody>
      </table>

      <div
          v-if="!readOnly"
          class="btn-group pull-right my-4"
      >
        <button
            type="button"
            class="btn btn-default dropdown-toggle"
            data-toggle="dropdown"
        >
          <i class="fa fa-plus" />
          {{ t("add_clearing_item") }}
          <i class="fa fa-caret-down" />
        </button>

        <ul class="dropdown-menu">
          <li v-for="it in availableClearingItems" :key="it">
            <a
                href="#"
                @click.prevent="addClearingItem(it)"
                v-text="t(`categories.${it}`)"
            />
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import PriceDisplay from "./PriceDisplay.vue"
import PriceInput from "./PriceInput.vue"
import NoteInput from "./NoteInput.vue"
import DestroyClearingItem from "./DestroyClearingItem.vue"

import axios from "axios"
import qs from "qs"
import { debounce } from "lodash"
import { currency as fmtCurrency } from "../CurrencyFormatter"
import { formatDateRange } from "../../lib/DateFormatter"

import { translate } from "@digineo/vue-translate"
const t = (key, params = {}) => translate(key, { ...params, scope: "price_table" })

const CATEGORIES = [
  "handling",
  "reversal",
  "pet_fee",
  "early_checkin",
  "late_checkout",
  "discount",
  "intervillas_discount",
  "repeater_discount",
  "travel_agency_discount",
  "boat_reversal",
  "boat_discount",
]

const TRAVELER = Object.freeze({
  discounts:  ["easter", "christmas", "high_season", "special"],
  categories: ["adults", "base_rate", "additional_adult", "children_under_6", "children_under_12"],

  extractFrom({ category: itemCat, minimum_people }) {
    let category, discount

    for (let i = 0, len = this.discounts.length; i < len; ++i) {
      const d = this.discounts[i]
      if (itemCat.endsWith(d)) {
        discount = t(`traveler_discounts.${d}`)
        break
      }
    }
    for (let i = 0, len = this.categories.length; i < len; ++i) {
      const c = this.categories[i]
      if (itemCat.startsWith(c)) {
        if (minimum_people) {
          category = t(`traveler_categories.${c}`, { count: minimum_people })
        } else {
          category = t(`traveler_categories.${c}`)
        }
        break
      }
    }
    return { category, discount }
  },
})

// Reihenfolge der Mietpreis-Kategorien
const CATEGORY_ORDER = [
  "base_rate",
  "weekly_rate",
  "base_rate_christmas",
  "base_rate_easter",
  "base_rate_high_season",
  "base_rate_special",
  "additional_adult",
  "additional_adult_christmas",
  "additional_adult_easter",
  "additional_adult_high_season",
  "additional_adult_special",
  "adults",
  "adults_christmas",
  "adults_easter",
  "adults_high_season",
  "adults_special",
  "children_under_12",
  "children_under_12_christmas",
  "children_under_12_easter",
  "children_under_12_high_season",
  "children_under_12_special",
  "children_under_6",
  "children_under_6_christmas",
  "children_under_6_easter",
  "children_under_6_high_season",
  "children_under_6_special",
]

function mkCatSort(collection) {
  return (e1, e2) => collection.indexOf(e1.category) - collection.indexOf(e2.category)
}

const categorySort = mkCatSort(CATEGORY_ORDER),
      clearingItemSort = mkCatSort(["cleaning", ...CATEGORIES])

export default {
  components: {
    PriceDisplay,
    PriceInput,
    NoteInput,
    DestroyClearingItem,
  },

  props: {
    clearingParams: { type: Object, default: () => ({}) },
    readOnly:       { type: Boolean, default: false },
    value:          { type: Object, default: undefined },
    currency:       { type: String, default: "EUR" },
  },

  data() {
    return {
      dataClearing: {},
      error:        "",
      refreshing:   false,
    }
  },

  computed: {
    other_clearing_items() {
      if (!this.clearing.other_clearing_items) {
        return []
      }
      if (!this.readOnly) {
        return this.clearing.other_clearing_items
      }
      return this.clearing.other_clearing_items.filter(ci => +ci.price !== 0)
    },

    clearing: {
      get() {
        if (this.value !== undefined) {
          // eslint-disable-next-line vue/no-side-effects-in-computed-properties
          this.dataClearing = this.value
        }
        return this.dataClearing
      },

      set(value) {
        this.dataClearing = value
        this.dataClearing.rentable_clearings?.forEach(rc => rc.rents.sort(categorySort))
        this.dataClearing.other_clearing_items?.sort(clearingItemSort)
        this.$emit("input", value)
        this.$emit("valid")
      },
    },

    availableClearingItems() {
      const list = [
        "handling",
        "reversal",
        "pet_fee",
        "early_checkin",
        "late_checkout",
        "discount",
        "intervillas_discount",
        "repeater_discount",
        "travel_agency_discount",
      ]
      if (this.clearingParams.boat && !this.clearingParams.boat.inclusive) {
        list.push("boat_reversal", "boat_discount")
      }
      return list
    },
  },

  beforeUpdate() {
    // NOTE(dom): if the PriceTable is rendered multiple times with
    // the same data, the date range is not displayed. This is just a
    // workaround, the root cause (multiple renderers) is very elusive.
    this.lastPeriod = null
  },

  mounted() {
    document.addEventListener("change-discount", this.requestClearing)
  },

  beforeDestroy() {
    document.removeEventListener("change-discount", this.requestClearing)
  },

  methods: {
    translate,
    t,
    fmtCurrency,

    active_clearing_items(clearingItems) {
      return clearingItems.filter(ci => !ci._destroy)
    },

    addClearingItem(category) {
      const clearing_item = {
        _destroy:       null,
        id:             null,
        category,
        inquiry_id:     this.clearingParams.inquiry_id,
        note:           null,
        human_category: t(`categories.${category}`),
        price:          {
          value:    0,
          currency: this.currency,
        },
      }

      if (["discount", "reversal", "repeater_discount", "pet_fee", "early_checkin", "late_checkout"].includes(category)) {
        clearing_item.villa_id = this.clearingParams.villa.villa_id
      }
      if (["boat_discount", "boat_reversal"].includes(category)) {
        clearing_item.boat_id = this.clearingParams.boat.boat_id
      }

      this.dataClearing.other_clearing_items.push(clearing_item)
      this.dataClearing.other_clearing_items.sort(clearingItemSort)
      if (this.value !== undefined) {
        this.$emit("input", this.dataClearing)
      }
    },

    showNoteInput(clearing_item) {
      return !this.readOnly && CATEGORIES.includes(clearing_item.category)
    },

    makeCurrencyValue(value) {
      return {
        value:    value,
        currency: this.currency,
      }
    },

    refreshTotal(clearing_item) {
      clearing_item.total = this.makeCurrencyValue((clearing_item.amount || 1) * (clearing_item.time_units || 1) * clearing_item.price.value)

      this.clearing.total_rents = this.makeCurrencyValue(this.clearing.rentable_clearings
        .flatMap(rc => rc.rents.map(ci => +ci.total.value))
        .reduce((sum, sub) => sum + sub, 0))

      this.clearing.sub_total = this.makeCurrencyValue(this.clearing.total_rents.value
        + this.clearing.other_clearing_items.reduce((sum, ci) => sum + ci.price.value, 0))

      this.clearing.total = this.makeCurrencyValue(this.clearing.sub_total.value
        + this.clearing.deposits.reduce((sum, ci) => sum + ci.price.value, 0))
    },

    period(period) {
      // this.lastPeriod darf nicht reaktiv sein, da sonst eine Update-Schleife entsteht
      if (this.lastPeriod
        && this.lastPeriod.start_date === period.start_date
        && this.lastPeriod.end_date === period.end_date) {
        return
      }

      this.lastPeriod = period
      return formatDateRange(period)
    },

    requestClearing: debounce(function() {
      this.refreshing = true
      axios.get("/api/inquiries/clearing.json", {
        params:           { currency: this.currency, ...this.clearingParams },
        paramsSerializer: qs.stringify,
      }).then(response => {
        this.clearing = response.data
        this.error = ""
        this.refreshing = false
      }).catch(err => {
        this.clearing = {}

        if (!this.readOnly) {
          const message = [t("invalid")]
          if (err.response.status === 422) {
            message.push(err.response.data)
          }

          this.error = message.join(" ")
        }

        this.$emit("invalid")
        this.refreshing = false
      })
    }, 500),

    clearingItemTitle(item) {
      const period = formatDateRange(item.period),
            units = item.human_time_units,
            amount = item.amount,
            rentable = item.villa_id ? "Villa" : "Boot",
            { category, discount } = TRAVELER.extractFrom(item)

      let s = `${rentable}: ${period}, ${units}`

      if (this.isBaseRate(item.category) && amount === 1) {
        s += `, ${category}`
      } else if (category && amount && amount > 0) {
        s += `, ${amount} ${category}`
      }
      if (discount) {
        s += ` (${discount})`
      }
      return s
    },

    isBaseRate(category) {
      return category === "weekly_rate" || category.startsWith("base_rate")
    },
  },
}
</script>

<style scoped lang="scss">
  .rule-bold {
    td, th {
      border-top: 2px solid #BBB;
      border-bottom: 2px solid #BBB;
    }
  }
</style>
