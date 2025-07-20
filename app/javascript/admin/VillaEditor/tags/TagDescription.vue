<template>
  <abbr
      v-if="subtitle"
      :title="subtitle"
      v-text="title"
  />
  <span
      v-else
      v-text="title"
  />
</template>

<script>
import { Tag } from "../models"

const RE = /^([^(]+) \((.*?)\)?$/

export default {
  props: {
    tag: { type: Tag, required: true },
  },

  computed: {
    parts() {
      const m = this.tag.description.match(RE)
      if (m) {
        return [m[1].trim(), m[2].trim()]
      }
      return null
    },

    title() {
      return this.parts ? this.parts[0] : this.tag.description
    },

    subtitle() {
      return this.parts ? this.parts[1] : null
    },
  },
}
</script>
