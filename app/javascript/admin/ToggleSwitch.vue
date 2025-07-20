<!-- similar, but not identical to ./ToggleActive -->
<template>
  <a
      :title="title"
      href="#"
      class="toggle-switch"
      :class="{ disabled }"
      @click.prevent="onClick"
  >
    <i
        class="fa fa-fw fa-lg"
        :class="iconClasses"
    />
    <slot />
  </a>
</template>

<script>
export default {
  props: {
    name:     { type: String, default: null },
    active:   { type: Boolean, required: true },
    disabled: { type: Boolean, default: false },
  },

  computed: {
    title() {
      return `${this.name || ""} ${this.active ? "de" : ""}aktivieren`.trim()
    },

    iconClasses() {
      return {
        "fa-toggle-off": !this.active,
        "fa-toggle-on":  this.active,
        "text-muted":    !this.active,
        "text-success":  this.active,
      }
    },
  },

  methods: {
    /**
     * Emits, when active, the desired active state (i.e. the inverse of
     * the current active prop value).
     */
    onClick() {
      if (!this.disabled) {
        this.$emit("click", !this.active)
      }
    },
  },
}
</script>

<style>
  a.toggle-switch {
    color: inherit;
  }
  a.toggle-switch.disabled {
    opacity: 0.8;
    cursor: not-allowed;
  }
</style>
