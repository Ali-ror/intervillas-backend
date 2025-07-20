<template>
  <div class="room-thumb" :data-villa-id="id">
    <div class="teaser-image">
      <img
          :src="thumbnailUrl"
          :srcset="`${thumbnailUrl}@2x 2x`"
          :alt="`${name} Florida`"
          width="356"
          height="228"
      >
      <div
          v-if="locality"
          class="locality"
          v-text="locality"
      />

      <FeedbackRating :rating="rating"/>
    </div>

    <div class="ident">
      <h4><a :href="searchUrl">{{ name }}</a></h4>

      <div class="price h5">
        {{ labels.price_from }} {{ priceFrom }}
      </div>
    </div>

    <small class="notes">{{ priceTimeUnit }}</small>

    <div class="features">
      <div>
        <i class="fa fa-fw fa-bed" />
        {{ bedrooms }}
      </div>
      <div>
        <i class="fa fa-fw fa-bath" />
        {{ bathrooms }}
      </div>
      <div>
        <i class="fa fa-fw fa-home" />
        {{ livingArea }}
      </div>
      <div>
        <i class="fa fa-fw fa-compass" />
        {{ poolOrientation }}
      </div>
    </div>
  </div>
</template>

<script>
import FeedbackRating from "./FeedbackRating.vue"

export default {
  components: {
    FeedbackRating,
  },

  props: {
    id:              { type: Number, required: true },
    name:            { type: String, required: true },
    locality:        { type: String, default: null },
    labels:          { type: Object, required: true },
    priceFrom:       { type: String, default: null },
    searchUrl:       { type: String, default: null },
    tags:            { type: Object, default: () => ({}) },
    thumbnailUrl:    { type: String, required: true },
    rating:          { type: Object, default: null },
    bedrooms:        { type: String, required: true },
    bedsCount:       { type: Number, required: true },
    minimumPeople:   { type: Number, required: true },
    bathrooms:       { type: String, required: true },
    livingArea:      { type: String, required: true },
    poolOrientation: { type: String, required: true },
    weeklyPricing:   { type: Boolean, default: false },
  },

  computed: {
    priceTimeUnit() {
      const { labels, weeklyPricing, bedsCount, minimumPeople } = this,
            mode = weeklyPricing ? "weekly" : "nightly",
            unit = labels.price_time_unit[mode]

      return unit.replace(/%{count}/, weeklyPricing ? bedsCount : minimumPeople)
    },
  },
}
</script>
