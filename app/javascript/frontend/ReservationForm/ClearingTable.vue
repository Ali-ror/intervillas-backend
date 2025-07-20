<template>
  <table class="table border-light border-bottom">
    <tbody v-if="showBreakdown">
      <tr>
        <th
            class="text-primary"
            colspan="2"
            v-text="t('person_prices')"
        />
      </tr>
      <tr v-for="item in rentItems" :key="item.id">
        <td class="border-top-0" v-text="item.human_category" />
        <td class="border-top-0 text-right" v-text="currency(item.price)" />
      </tr>
      <tr>
        <th
            class="text-primary"
            colspan="2"
            v-text="t('other_prices')"
        />
      </tr>
      <tr v-for="item in chargeItems" :key="item.id">
        <td class="border-top-0" v-text="item.human_category" />
        <td class="border-top-0 text-right" v-text="currency(item.price)" />
      </tr>
      <tr v-for="item in otherItems" :key="item.id">
        <td class="border-top-0" v-text="item.human_category" />
        <td class="border-top-0 text-right" v-text="currency(item.price)" />
      </tr>
    </tbody>

    <tbody>
      <tr>
        <th v-text="t('total_rent')" />
        <td class="text-right" v-text="currency(totalRents)" />
      </tr>
      <tr v-if="!showBreakdown || depositItems.length < 2">
        <td v-text="t('plus_deposit')" />
        <td class="text-right" v-text="currency(totalDeposits)" />
      </tr>
      <template v-else>
        <tr v-for="item in depositItems" :key="item.id">
          <td v-text="`${t('plus')} ${item.human_category}`" />
          <td class="text-right" v-text="currency(item.price)" />
        </tr>
      </template>
    </tbody>
    <tfoot v-if="!noFooter">
      <tr>
        <td colspan="2" class="text-right">
          <span class="small text-muted pull-left" v-text="t('tax_included')" />

          <button
              type="button"
              class="btn btn-xxs btn-default"
              @click.prevent="showBreakdown = !showBreakdown"
          >
            <i class="fa" :class="showBreakdown ? 'fa-minus' : 'fa-plus'" />
            {{ t(showBreakdown ? "details.less" : "details.more") }}
          </button>
        </td>
      </tr>
    </tfoot>
  </table>
</template>

<script>
import { currency } from "../../admin/CurrencyFormatter"

import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "reservation_form.clearing" })

const RENT_CATEGORIES = Object.freeze([
  "base_rate",
  "weekly_rate",
  "additional_adult",
  "adults",
  "children_under_12",
  "children_under_6",
])

/**
 * Sort function. Arranges items by `category`, in the order defined
 * in `RENT_CATEGORIES`.
 *
 * @param {{ category: string }} a
 * @param {{ category: string }} b
 */
const byCategory = (a, b) => RENT_CATEGORIES.indexOf(a.category) - RENT_CATEGORIES.indexOf(b.category)

const surchargeName = category => {
  for (const [key, human_category] of Object.entries(t("surcharges"))) {
    if (category.endsWith(`_${key}`)) {
      return [key, human_category]
    }
  }
  return []
}

/**
 * Sums up the given items' `price` values.
 *
 * @param {{ price: number }[]} items
 * @return {number} sum
 */
const sumPrices = (...items) => items.reduce((total, item) => total + item.price, 0)

export default {
  props: {
    clearing:  { type: Object, required: true },
    breakdown: { type: Boolean, default: false }, // opens price breakdown (ignored if noFooter is true)
    noFooter:  { type: Boolean, default: false }, // hides breakdown toggle
  },

  data() {
    return {
      showBreakdown: this.breakdown || this.noFooter,
    }
  },

  computed: {
    totalRents() {
      return sumPrices(...this.rentItems, ...this.chargeItems, ...this.otherItems)
    },

    /** sum of all deposit items */
    totalDeposits() {
      return sumPrices(...this.depositItems)
    },

    /** person prices (adults, children-12, children-6), boat rental */
    rentItems() {
      return this.clearing.rentable_clearings.reduce((rents, curr) => {
        for (let i = 0, len = curr.rents.length; i < len; ++i) {
          const rent = curr.rents[i],
                { category } = rent
          if (RENT_CATEGORIES.includes(category)) {
            const { human_category, human_time_units, time_units, start_date, total } = rent
            rents.push({
              id:    `${category}/${start_date}/${time_units}`,
              category,
              human_category,
              human_time_units,
              price: total.value,
            })
          }
        }
        return rents
      }, []).sort(byCategory)
    },

    /** surcharges (holidays, high season), discount (last minute) */
    chargeItems() {
      return Object.values(this.clearing.rentable_clearings.reduce((group, curr) => {
        for (let i = 0, len = curr.rents.length; i < len; ++i) {
          const charge = curr.rents[i],
                { category } = charge,
                [key, human_category] = surchargeName(category)

          if (key) {
            const { start_date, total } = charge,
                  id = `${key}/${start_date}`

            group[id] || (group[id] = { id, human_category, price: 0 })
            group[id].price += total.value
          }
        }
        return group
      }, {}))
    },

    /** house cleaning, boat delivery ("training") */
    otherItems() {
      return Object.values(this.clearing.other_clearing_items.reduce((group, curr) => {
        const { villa_id, boat_id, category, human_category, price } = curr,
              id = `${category}/${villa_id ? "villa" : boat_id ? "boat" : "?"}`

        group[id] || (group[id] = { id, human_category, price: 0 })
        group[id].price += price.value

        return group
      }, {}))
    },

    /** villa and boat deposit */
    depositItems() {
      return Object.values(this.clearing.deposits.reduce((group, curr) => {
        const { villa_id, boat_id, category, human_category, price } = curr,
              id = `${category}/${villa_id ? "villa" : boat_id ? "boat" : "?"}`

        group[id] || (group[id] = { id, human_category, price: 0 })
        group[id].price += price.value

        return group
      }, {}))
    },
  },

  methods: {
    t,

    currency(val) {
      return currency(val, this.clearing.currency)
    },
  },
}
</script>
