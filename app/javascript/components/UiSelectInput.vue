<!--
  Wrapper um `<UiSelect />` für Formtastic

  Bitte in neuen Anwendungen `<UiSelect />` direkt verwenden. Diese Komponente
  dient nur dazu, vorhandene `f.input ... as: :ui_select`-Stellen zu bedienen.
-->

<template>
  <div style="width: 100%">
    <template v-if="multiple">
      <input
          v-for="v, i in value"
          :key="i"
          type="hidden"
          :name="name"
          :value="v"
      >
    </template>
    <input
        v-else
        type="hidden"
        :name="name"
        :value="selected"
    >
    <UiSelect
        :id="id"
        v-model="selected"
        :options="options.map(([label, value]) => ({ label, value }))"
        :reduce="option => option.value"
        :multiple="multiple"
        :placeholder="placeholder"
        :clearable="clearable"
        :append-to-body="appendToBody"
    />
  </div>
</template>

<script>
import UiSelect from "./UiSelect.vue"

export default {
  components: {
    UiSelect,
  },

  props: {
    id:           { type: String, required: true },
    name:         { type: String, required: true },
    value:        { type: [Array, String, Number], default: null },
    options:      { type: Array, default: () => ([]) },
    multiple:     { type: Boolean, default: false },
    placeholder:  { type: String, default: "" },
    clearable:    { type: Boolean, default: false },
    appendToBody: { type: Boolean, default: false },
  },

  data() {
    return {
      selected: this.value,
    }
  },
}
</script>
