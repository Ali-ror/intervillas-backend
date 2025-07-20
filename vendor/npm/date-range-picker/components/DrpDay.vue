<template>
  <a
      class="date"
      :class="annotations"
      :href="href"
      @click.prevent="handle('select', 'cancel')"
      @mouseover.prevent="handle('hover')"
      v-text="content"
  />
</template>

<script>
import Day from "../pickable/day"
import { fmt } from "../utils"

export default {
  name: "DrpDay",

  props: {
    day: { type: Day, required: true },
  },

  computed: {
    href() {
      return `#!/${fmt(this.day.date)}`
    },

    annotations() {
      return this.day.annotations
    },

    clickable() {
      return !this.annotations.blocked && !this.annotations["other-month"]
    },

    content() {
      return this.annotations["other-month"]
        ? ""
        : this.day.toString()
    },
  },

  methods: {
    handle(whenClickable, otherwise) {
      if (this.clickable) {
        this.$emit(whenClickable)
      } else if (otherwise) {
        this.$emit(otherwise)
      }
    },
  },
}
</script>
