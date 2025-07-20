<template>
  <AdminMediaGallery
      v-bind="api.images"
  />
</template>

<script>
import Common from "./common"

export default {
  mixins: [Common],
}
</script>
