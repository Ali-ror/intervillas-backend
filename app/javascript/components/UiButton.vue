<template>
  <a
      v-if="url"
      class="btn"
      :href="disabled ? undefined : url"
      :class="buttonClasses"
      @click="$emit('click', $event)"
  >
    <slot>
      <i
          v-if="icon"
          class="fa"
          :class="iconClasses"
      />
      {{ label }}
    </slot>
  </a>
  <button
      v-else
      class="btn"
      :disabled="disabled"
      :type="type"
      :class="buttonClasses"
      @click="$emit('click', $event)"
  >
    <slot>
      <i
          v-if="icon"
          class="fa"
          :class="`fa-${icon}`"
      />
      {{ label }}
    </slot>
  </button>
</template>

<script>
export default {
  props: {
    type:     { type: String, default: "button" }, // e.g. "submit", "reset"
    variant:  { type: String, default: "default" },
    disabled: { type: Boolean, default: false },
    size:     { type: String, default: "md" }, // "xxs" | "xs" | "sm" | "md" | "lg"
    icon:     { type: [Array, String], default: null },
    label:    { type: String, default: null },
    block:    { type: Boolean, default: false },
    url:      { type: String, default: null }, // creates <a/> instead of <button/>
  },

  computed: {
    buttonClasses() {
      return [
        ...(this.size ? [`btn-${this.size}`] : []),
        ...(this.variant ? [`btn-${this.variant}`] : []),
        ...(this.disabled ? ["disabled"] : []),
        ...(this.block ? ["btn-block"] : []),
      ]
    },

    iconClasses() {
      if (Array.isArray(this.icon)) {
        return this.icon.map(i => `fa-${i}`)
      }
      return `fa-${this.icon}`
    },
  },
}
</script>
