<template>
  <div>
    <h2>
      Vorschau/Bearbeiten

      <a
          v-if="medium"
          href="#"
          class="close"
          title="schließen"
          @click.prevent="$emit('close')"
      ><i class="fa fa-times" /></a>
    </h2>

    <template v-if="medium">
      <Preview :medium="medium"/>
      <EditFields
          :medium="medium"
          :image-tags="imageTags"
          @updated="$emit('updated', medium.id, $event)"
          @destroyed="$emit('destroyed', medium.id)"
      />
    </template>

    <div
        v-else
        class="well text-center text-muted"
    >
      Kein Bild ausgewählt.
    </div>
  </div>
</template>

<script>
import EditFields from "./EditFields.vue"
import Preview from "./Preview.vue"

export default {
  components: {
    EditFields,
    Preview,
  },

  props: {
    medium:    { type: Object, default: null },
    imageTags: { type: Array, default: null },
  },
}
</script>
