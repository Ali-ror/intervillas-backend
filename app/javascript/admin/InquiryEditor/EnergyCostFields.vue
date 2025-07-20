<template>
  <tr>
    <td :colspan="readOnly ? 2 : 3" />
    <td colspan="2">
      {{ t("label") }}
      <div class="small text-muted" v-text="source"/>
    </td>
    <td class="text-right">
      <span
          v-if="isLegacy"
          class="text-muted"
          v-text="t('options.defer')"
      />
      <span v-else-if="readOnly">
        {{ selectedValueHuman }}
      </span>
      <select
          v-else
          class="form-control"
          v-model="ecc"
      >
        <optgroup :label="t('preset')">
          <option :value="preset" v-text="t(`options.${preset}`)" />
        </optgroup>
        <optgroup :label="t('override')">
          <option
              v-for="o in eccOptions"
              :key="o.value"
              :value="o.value"
          >* {{ o.label }}</option>
        </optgroup>
      </select>
    </td>
  </tr>
</template>

<script>
import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "inquiry_editor.energy_cost" })

export default {
  props: {
    value:    { type: String, default: null },
    preset:   { type: String, required: true },
    readOnly: { type: Boolean, default: false },
  },

  computed: {
    ecc: {
      get() {
        return this.value || this.preset
      },

      set(val) {
        this.$emit("input", val)
      },
    },

    eccOptions() {
      if (this.isLegacy) {
        return []
      }
      return ["defer", "usage", "flat", "included"].map(o => ({
        value: `override_${o}`,
        label: t(`options.${o}`),
      }))
    },

    isPreset() {
      return this.value === this.preset
    },

    isLegacy() {
      return this.value === "legacy"
    },

    isOverride() {
      return this.value?.startsWith("override_")
    },

    source() {
      const label = this.isPreset
        ? "preset"
        : this.isLegacy
          ? "legacy"
          : this.isOverride
            ? "override"
            : "notreached"

      return label ? t(label) : undefined
    },

    selectedValueHuman() {
      if (this.isOverride) {
        const [_, value] = this.value.split("_")
        return t(`options.${value}`)
      }
      if (this.value) {
        return t(`options.${this.value}`)
      }
      return "unknown"
    },
  },

  methods: {
    t,
  },
}
</script>
