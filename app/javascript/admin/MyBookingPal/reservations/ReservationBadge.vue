<template>
  <span
      class="label"
      :class="variant"
      v-text="type"
  />
</template>

<script>
export default {
  props: {
    type: { type: String, required: true },
  },

  computed: {
    variant() {
      switch (this.type) {
      case "create":
        return "label-success"
      case "upcate":
        return "label-warning"
      case "cancel":
        return "label-danger"
      }
      return "label-info"
    },
  },
}
</script>
