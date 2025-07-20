<template>
  <div class="promo-video video-preview">
    <a :href="url" @click.prevent="showModal">
      <img class="img-responsive" :src="placeholder">
    </a>

    <VModal
        name="promo-video"
        class="bg-dark"
        v-bind="modalProps"
        @before-close="onCloseModal"
    >
      <iframe
          :src="embedURL"
          frameborder="0"
          allow="autoplay; encrypted-media"
          allowfullscreen
      />
    </VModal>
  </div>
</template>

<script>
import promoVideoImg from "./promo-video.jpg"
import { reflowMixin } from "../lib/youtube"

export default {
  name: "PromoVideo",

  mixins: [reflowMixin],

  data() {
    return {
      videoID:     null,
      placeholder: promoVideoImg,
    }
  },

  computed: {
    url() {
      return `https://www.youtube.com/watch?v=${this.videoID}`
    },

    embedURL() {
      return `https://www.youtube.com/embed/${this.videoID}?rel=0&amp;showinfo=0&amp;autoplay=1`
    },
  },

  beforeMount() {
    const ds = this.$el.dataset
    this.videoID = ds.v
  },

  methods: {
    showModal() {
      document.querySelector("body").style.overflow = "hidden"
      this.$modal.show("promo-video")
    },

    onCloseModal() {
      document.querySelector("body").style.overflow = ""
    },
  },
}
</script>
