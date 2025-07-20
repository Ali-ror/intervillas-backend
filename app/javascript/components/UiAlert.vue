<template>
  <div class="alert" :class="variantClass">
    <slot />
  </div>
</template>

<script>
export default {
  props: {
    variant: { type: String, default: "info" },
  },

  computed: {
    variantClass() {
      return `alert-${this.variant}`
    },
  },
}
</script>
