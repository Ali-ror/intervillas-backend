<template>
  <table class="table table-striped table-condensed">
    <thead>
      <tr>
        <th v-text="t('period')" />
        <th class="text-right" v-text="t('per_day')" />
        <th class="text-right" v-text="t('total')" />
      </tr>
    </thead>
    <tbody>
      <tr v-for="price in decoratedPrices" :key="price.days">
        <td v-text="price.days" />
        <td class="text-right" v-text="price.per_day" />
        <td class="text-right" v-text="price.total" />
      </tr>
    </tbody>
  </table>
</template>

<script>
import { translate, pluralize } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "boat_booking.prices" })

export default {
  props: {
    prices: { type: Array, required: true },
  },

  computed: {
    decoratedPrices() {
      const maxIdx = this.prices.length - 1
      return this.prices.map(({ days, per_day, total }, idx) => {
        let scope = "normal"
        if (idx === 0) {
          scope = "min"
        } else if (idx === maxIdx) {
          scope = "max"
          total = [t("starting_from"), total].join(" ")
        }
        return {
          days: pluralize(days, `boat_booking.prices.days.${scope}`),
          per_day,
          total,
        }
      })
    },
  },

  methods: {
    t,
  },
}
</script>
