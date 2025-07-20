<template>
  <strong
      v-if="header"
      class="small"
      v-text="name"
  />
  <div
      v-else
      class="d-flex justify-content-between align-items-baseline gap-3"
      :class="opt.textClass"
  >
    {{ name }}

    <span
        class="label"
        :class="opt.labelClass"
        v-text="opt.labelText"
    />
  </div>
</template>

<script>
const MIN_BOAT_DAYS = 1

export default {
  props: {
    header: { type: Boolean, default: false },
    name:   { type: String, required: true },
    free:   { type: Array, default: () => ([]) },
  },

  computed: {
    opt() {
      const n = this.free.length
      if (n < MIN_BOAT_DAYS) {
        return {
          textClass:  "text-danger",
          labelClass: "label-danger",
          labelText:  "X",
        }
      }
      return {
        textClass:  null,
        labelClass: "label-success",
        labelText:  `${n}`,
      }
    },
  },
}
</script>
