<template>
  <figure>
    <ProgressPlaceholder
        v-if="medium.type === 'upload'"
        :upload="medium"
        :width="containerWidth"
        :height="100"
    />

    <iframe
        v-else-if="medium.preview_url && (['tour', 'pannellum'].includes(medium.type))"
        :src="medium.preview_url"
        :width="containerWidth"
        :height="(3/4) * containerWidth"
        frameborder="0"
    />

    <img
        v-else-if="medium.type === 'image' || medium.type === 'slide'"
        :src="medium.preview_url"
        class="img-thumbnail"
    >

    <div
        v-else
        class="well text-center text-muted"
    >
      <i class="fa fa-eye-slash fa-2x" /><br>
      <em>Vorschau derzeit nicht verfügbar.</em>
    </div>

    <figcaption class="text-right mt-2">
      <a
          v-if="medium.download_url"
          class="btn btn-xxs btn-default"
          :href="medium.download_url"
      >
        <i class="fa fa-cloud-download" />
        Original herunterladen
      </a>
    </figcaption>
  </figure>
</template>

<script>
import ProgressPlaceholder from "./ProgressPlaceholder.vue"

export default {
  components: {
    ProgressPlaceholder,
  },

  props: {
    medium: { type: Object, default: null },
  },

  data() {
    return {
      containerWidth: 100,
    }
  },

  mounted() {
    this.containerWidth = this.$el.getBoundingClientRect().width
  },
}
</script>
