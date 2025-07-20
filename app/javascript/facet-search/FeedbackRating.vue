<template>
  <div v-if="rating !== null" class="feedbacks">
    <i
        v-for="(klass, i) in stars"
        :key="i"
        class="fa"
        :class="klass"
    />
  </div>
</template>

<script>
export default {
  props: {
    rating: { type: Object, default: null },
  },

  computed: {
    stars() {
      if (this.rating === null) {
        return
      }

      const s = this.rating.stars,
            stars = []

      for (let i = 0, len = s[0]; i < len; ++i) {
        stars.push("fa-star")
      }
      for (let i = 0, len = s[1]; i < len; ++i) {
        stars.push("fa-star-half-o")
      }
      for (let i = 0, len = 5 - (s[0] + s[1]); i < len; ++i) {
        stars.push("fa-star-o")
      }
      return stars
    },
  },
}
</script>
