<template>
  <ReviewEditor
      :endpoint="api.reviews"
  />
</template>

<script>
import Common from "./common"
import ReviewEditor from "../ReviewEditor.vue"

export default {
  components: {
    ReviewEditor,
  },

  mixins: [Common],
}
</script>
