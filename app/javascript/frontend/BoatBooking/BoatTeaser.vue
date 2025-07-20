<template>
  <div class="room-thumb boat" :class="`availability-${boat.availability.key}`">
    <div v-if="boat.thumbnails" class="teaser-image">
      <img :src="thumbSrc" :srcset="thumbSrcset">
      <span
          v-if="boat.availability.key !== 'full'"
          class="availability-badge"
          v-text="boat.availability.title"
      />
    </div>
    <div class="ident">
      <h4
          v-if="boat.availability.key === 'none'"
          v-text="boat.model"
      />
      <h4 v-else>
        <a
            :href="`#/${boat.id}/${boat.model}`"
            @click.prevent="emitBoat"
            v-text="boat.model"
        />
      </h4>
    </div>
    <small class="notes" v-text="boat.note" />
  </div>
</template>

<script>
export default {
  props: {
    boat: { type: Object, required: true },
  },

  computed: {
    thumbSrc() {
      return this.boat.thumbnails[0][0]
    },

    thumbSrcset() {
      return this.boat.thumbnails.slice(1)
        .map(([url, dpr]) => `${url} ${dpr}`)
        .join(", ")
    },
  },

  methods: {
    emitBoat() {
      if (this.boat.availability.key !== "none") {
        this.$emit("show-details")
      }
    },
  },
}
</script>

<style lang="scss">
  .availability-none {
    img {
      filter: opacity(0.5) grayscale(1);
    }
  }

  .availability-badge {
    position: absolute;
    top: 6px;
    left: 12px;
    background: rgba(#75c5cf, 0.8);
    color: #fff;
    width: 40%;
    padding: 3px 6px;
    border-radius: 3px;
  }
</style>
