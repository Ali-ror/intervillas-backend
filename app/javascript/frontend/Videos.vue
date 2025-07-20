<template>
  <div class="text-center">
    <div class="visible-md visible-lg">
      <template v-if="videos.length > 1">
        <a
            v-for="(video, i) of videos"
            :key="i"
            :href="video.url"
            class="btn btn-panorama"
            :class="active === video ? 'btn-primary' : 'btn-default'"
            @click.prevent="active = video"
            v-text="video.name"
        />
      </template>

      <div class="video-preview mt-4">
        <a
            v-if="active"
            :href="active.url"
            @click.prevent="showModal(active)"
        >
          <RetinaImage class="img-responsive" :src="active.preview"/>
        </a>
      </div>
    </div>

    <div class="visible-xs visible-sm">
      <a
          v-for="(video, i) of videos"
          :key="i"
          :href="video.url"
          class="btn btn-default btn-panorama"
          @click.prevent="showModal(video)"
          v-text="video.name"
      />
    </div>

    <VModal
        name="video"
        class="bg-dark"
        v-bind="modalProps"
        @before-close="onCloseModal"
    >
      <iframe
          :src="embedUrl"
          frameborder="0"
          allow="autoplay; encrypted-media"
          allowfullscreen
      />
    </VModal>
  </div>
</template>

<script>
import RetinaImage from "../frontend/RetinaImage.vue"
import { embedUrl, reflowMixin } from "../lib/youtube"

export default {
  name: "VillaVideos",

  components: {
    RetinaImage,
  },

  mixins: [reflowMixin],

  props: {
    videos: { type: Array, required: true },
  },

  data() {
    return {
      active: this.videos[0],
    }
  },

  computed: {
    embedUrl() {
      if (!this.active) {
        return null
      }
      return embedUrl(this.active.url)
    },
  },

  methods: {
    showModal(video) {
      this.active = video
      document.querySelector("body").style.overflow = "hidden"
      this.$modal.show("video")
    },

    onCloseModal() {
      document.querySelector("body").style.overflow = ""
    },
  },
}
</script>
