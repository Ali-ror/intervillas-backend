<!-- similar, but not identical to ./ToggleSwitch -->
<template>
  <a
      class="toggle-active"
      href="#"
      :class="wrapperClass"
      @click.prevent="toggle()"
  >
    <i class="fa fa-lg" :class="iconClass" />
    {{ text }}
  </a>
</template>

<script>
import Utils from "../intervillas-drp/utils"

export default {
  props: {
    url:          { type: String, required: true },
    activeText:   { type: String, default: "ja" },
    inactiveText: { type: String, default: "nein" },
    disabledText: { type: String, default: "deaktiviert" },
    active:       { type: Boolean, default: false },
    disabled:     { type: Boolean, default: false },
  },

  data() {
    return {
      loading:  false,
      isActive: this.active,
    }
  },

  computed: {
    text() {
      return `${this.disabled ? this.disabledText : this.isActive ? this.activeText : this.inactiveText}${this.loading ? "..." : ""}`
    },

    wrapperClass() {
      return {
        "disabled":     this.disabled,
        "text-muted":   this.disabled,
        "text-success": !this.disabled && this.isActive,
        "text-danger":  !this.disabled && !this.isActive,
      }
    },

    iconClass() {
      return {
        "text-muted":    this.disabled,
        "text-success":  !this.disabled && this.isActive,
        "text-danger":   !this.disabled && !this.isActive,
        "fa-toggle-on":  !this.disabled && this.isActive,
        "fa-toggle-off": this.disabled || !this.isActive,
      }
    },
  },

  methods: {
    async toggle() {
      if (this.disabled || this.loading) {
        return
      }

      this.loading = true
      try {
        const data = await Utils.patchJSON(this.url)
        this.isActive = data.active
      } catch (err) {
        console.error("toggle-active failed:", err)
      } finally {
        this.loading = false
      }
    },
  },
}
</script>

<style lang="sass">
.toggle-active
  display: inline-block
  white-space: nowrap

  &:hover, &:focus, &:active
    text-decoration: none
</style>
