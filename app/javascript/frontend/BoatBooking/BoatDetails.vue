<template>
  <div :id="`boat_${boat.id}`" class="row">
    <div class="col-md-6">
      <slot />

      <h4 v-text="t('title', { scope: 'boat_booking.prices' })" />
      <BoatDetailsDailyPrices :prices="boat.daily_prices"/>

      <p v-for="d in discounts" :key="d.id">
        {{ d.name_amount }} <span class="small" v-text="d.range" />
      </p>
    </div>

    <div class="col-md-6">
      <h4 v-text="t('description')" />
      <table class="table table-striped table-condensed">
        <tbody>
          <tr>
            <th v-text="t('hp')" />
            <td v-text="t('hp_value', { ps: boat.horse_power })" />
          </tr>
          <tr v-if="videoLink">
            <th v-text="t('video')" />
            <td>
              <a
                  :href="videoLink.url"
                  class="text-nowrap"
                  target="_blank"
              >
                <i class="fa" :class="videoLink.icon" />
                {{ videoLink.text }}
              </a>
            </td>
          </tr>
          <tr>
            <th v-text="t('training')" />
            <td v-text="boat.prices.training" />
          </tr>
          <tr>
            <th v-text="t('deposit')" />
            <td v-text="boat.prices.deposit" />
          </tr>
          <tr v-if="boat.availability.key === 'limited'">
            <th v-text="t('availability')" />
            <td v-text="boat.availability.desc" />
          </tr>
        </tbody>
      </table>
      <!-- eslint-disable-next-line vue/no-v-html -->
      <div v-html="boat.description" />
    </div>
  </div>
</template>

<script>
import BoatDetailsDailyPrices from "./BoatDetailsDailyPrices.vue"

import { translate } from "@digineo/vue-translate"
const t = (key, params = {}) => translate(key, { scope: "boat_booking.details", ...params })

const YT_LINK = /^https?:\/\/(www\.)?youtu\.?be/i

export default {
  components: {
    BoatDetailsDailyPrices,
  },

  props: {
    boat: { type: Object, required: true },
  },

  computed: {
    discounts() {
      return this.boat.discounts.map(({ discount, percent, days_before, days_after }) => ({
        name_amount: t("discount.name_amount", { discount, percent }),
        range:       t("discount.range", { days_before, days_after }),
      }))
    },

    videoLink() {
      const { url } = this.boat
      if (!url) {
        return null
      }

      const yt = YT_LINK.test(url)
      return {
        icon: yt ? ["fa-youtube-play", "text-danger"] : ["fa-external-link"],
        text: yt ? "YouTube" : new URL(url).host,
        url,
      }
    },
  },

  methods: {
    t,
  },
}
</script>
