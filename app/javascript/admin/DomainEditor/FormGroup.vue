<template>
  <div :id="label ? null : id" class="form-group">
    <label
        v-if="label"
        :for="id"
        :class="labelClasses"
        class="control-label"
    >
      <span @click="$emit('labelClick')" v-text="label" />
      <HelpButton v-if="help" :item="help"/>
    </label>

    <div :class="fieldClasses">
      <slot />
    </div>

    <slot name="after" />
  </div>
</template>

<script>
import HelpButton from "./HelpButton.vue"

export default {
  components: {
    HelpButton,
  },

  props: {
    split: { type: Array, default: () => ([3, 9]) },
    id:    { type: String, required: true },
    label: { type: [String, Boolean], required: true },
    help:  { type: String, default: null },
  },

  computed: {
    labelClasses() {
      if (this.label) {
        return `col-sm-${this.split[0]}`
      }
      return null
    },

    fieldClasses() {
      if (this.label) {
        return `col-sm-${this.split[1]}`
      }
      return [`col-sm-offset-${this.split[0]}`, `col-sm-${this.split[1]}`]
    },
  },
}
</script>
