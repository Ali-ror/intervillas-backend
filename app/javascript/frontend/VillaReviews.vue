<template>
  <div>
    <div
        v-masonry
        item-selector=".review"
        transition-duration="0s"
        class="row"
    >
      <div
          v-for="review in reviews"
          :key="review.id"
          v-masonry-tile
          itemscope="itemscope"
          itemtype="http://schema.org/Review"
          class="review col-md-4"
      >
        <div
            itemprop="review"
            itemscope="itemscope"
            itemtype="http://schema.org/Review"
            class="text-balloon"
        >
          <strong><a
              :href="review.villa_path"
          >{{ review.villa_name }}</a></strong>
          <div
              itemprop="reviewRating"
              itemscope="itemscope"
              itemtype="http://schema.org/Rating"
              class="rating"
          >
            <meta itemprop="worstRating" content="1">
            <meta itemprop="ratingValue" :content="review.rating">
            <meta itemprop="bestRating" content="5">
            <!-- Das CSS für die Sternebewertung ist etwas unintuitiv. -->
            <!-- Nur der n-te Stern von rechts bekommt 'active', n = review.rating + 1 -->
            <i
                v-for="index in 5"
                :key="`star-${index}-${review.rating}`"
                class="star"
                :class="6 - review.rating === index ? 'active' : ''"
            />
          </div>
          <div itemprop="description">
            <!-- eslint-disable vue/no-v-html -->
            <p v-html="review.text" />
            <!-- eslint-enable vue/no-v-html -->
          </div>
          <p class="small">
            <span itemprop="author">{{ review.name }}</span>
            &bull;
            <span>{{ review.city }}</span>
          </p>
          <meta itemprop="datePublished" :content="review.published_on">
          &bull;
          <span>{{ review.published_on | formatDate }}</span>
          <p />
        </div>
      </div>
    </div>
    <InfiniteLoading @infinite="infiniteHandler">
      <div slot="no-more">
        {{ "infinite_loading.no_more" | translate }}
      </div>
      <div slot="no-results">
        {{ "infinite_loading.no_results" | translate }}
      </div>
      <div slot="error">
        {{ "infinite_loading.error" | translate }}
      </div>
    </InfiniteLoading>
  </div>
</template>

<script>
import axios from "axios"
import { formatDate } from "../lib/DateFormatter"
import InfiniteLoading from "vue-infinite-loading"
import { translate } from "@digineo/vue-translate"

export default {
  name: "VillaReviews",

  components: {
    InfiniteLoading,
  },

  filters: {
    formatDate,
  },

  props: {
    villaId: { type: Number, required: false, default: null },
  },

  data() {
    return {
      reviews: [],
      page:    1,
    }
  },

  methods: {
    translate,

    async infiniteHandler($state) {
      let params = { page: this.page }
      if (this.villaId) {
        params.villa_id = this.villaId
      }

      const response = await axios.get("/reviews.json", { params })
      let reviewsReturned = response.data
      if (!reviewsReturned.length) {
        return $state.complete()
      }

      this.reviews.push(...reviewsReturned)
      this.page++
      $state.loaded()
    },
  },
}
</script>
