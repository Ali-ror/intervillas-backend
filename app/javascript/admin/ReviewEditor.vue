<template>
  <Loading v-if="state === 'loading'"/>

  <div v-else>
    <ReviewList
        v-if="state === 'index' && reviews.length"
        :reviews="reviews"
        @edit="edit($event)"
        @destroy="destroy($event)"
        @toggle-publish="togglePublish($event)"
    />

    <div
        v-else-if="state === 'index'"
        class="alert alert-warning"
    >
      Noch keine Bewertungen vorhanden.
    </div>

    <ReviewEdit
        v-else
        :review="review"
        @save="saveReview"
        @cancel="cancelEdit"
    />
  </div>
</template>

<script>
import Loading from "./Loading.vue"
import Utils from "../intervillas-drp/utils"

import { Review } from "./ReviewEditor/review"
import ReviewList from "./ReviewEditor/List.vue"
import ReviewEdit from "./ReviewEditor/Edit.vue"

export default {
  components: {
    Loading,
    ReviewList,
    ReviewEdit,
  },

  props: {
    endpoint: { type: String, required: true },
  },

  data() {
    return {
      state:   "loading", // "loading" -> "index" <-> "edit"
      reviews: [],
      review:  null, // a (cloned) review passed to the edit form
      scrollY: 0, // store/restore scroll position when opening/closing edit form
    }
  },

  watch: {
    state(toState, fromState) {
      if (fromState === "index") {
        this.scrollY = window.scrollY
      } else if (toState === "index") {
        this.$nextTick(() => {
          window.scrollTo(0, this.scrollY)
        })
      }
    },
  },

  mounted() {
    Utils.fetchJSON(this.endpoint).then(reviews => {
      this.reviews = reviews.map(r => new Review(r))
      this.state = "index"
    })
  },

  methods: {
    edit(review) {
      this.scrollY = window.scrollY
      this.review = review.clone()
      this.state = "edit"
    },

    cancelEdit() {
      this.review = null
      this.state = "index"
    },

    saveReview() {
      Utils.patchJSON(this.review.url, { reviews: this.review }).then(data => {
        this.replaceReview(data)
        this.state = "index"
      })
    },

    destroy(review) {
      if (!confirm("Die Bewertung wird unwiderruflich gelöscht. Fortfahren?")) {
        return
      }

      Utils.deleteJSON(review.url).then(() => {
        const i = this.reviews.findIndex(r => r.id === review.id)
        if (i >= 0) {
          this.$delete(this.reviews, i)
        }
      })
    },

    togglePublish(review) {
      const payload = {
        published_at: review.published_at ? null : new Date(),
      }

      Utils.putJSON(review.url, { review: payload }).then(data => {
        this.replaceReview(data)
      })
    },

    replaceReview(data) {
      const i = this.reviews.findIndex(r => r.id === data.id)
      if (i >= 0) {
        this.$set(this.reviews, i, new Review(data))
        this.review = null
      }
    },
  },
}
</script>
