<template>
  <VueSelect
      v-model="selected"
      :input-id="id"
      :options="options"
      :selectable="selectable"
      :reduce="reduce"
      :clearable="clearable"
      :multiple="multiple"
      :components="components"
      :label="label"
      class="form-control"
      :placeholder="placeholder"
      :disabled="disabled"
      :append-to-body="appendToBody"
  >
    <template v-if="template || $scopedSlots['selected-option']" #selected-option="option">
      <slot
          v-if="$scopedSlots['selected-option']"
          name="selected-option"
          v-bind="option"
      />
      <Component
          :is="template"
          v-else
          v-bind="option"
      />
    </template>

    <template v-if="template || $scopedSlots.option" #option="option">
      <slot
          v-if="$scopedSlots.option"
          name="option"
          v-bind="option"
      />
      <Component
          :is="template"
          v-else
          v-bind="option"
      />
    </template>

    <template #no-options="{ search, loading, searching }">
      <span v-if="loading" class="text-muted">
        Lade Ergebnisse für <em>{{ search }}</em>&hellip;
      </span>
      <span v-else-if="searching" class="text-muted">
        Keine Ergebnisse für <em>{{ search }}</em> gefunden.
      </span>
      <span v-else class="text-muted">
        Keine Ergebnisse gefunden.
      </span>
    </template>
  </VueSelect>
</template>

<script>
import VueSelect from "vue-select"

export default {
  components: {
    VueSelect,
  },

  props: {
    id:           { type: String, default: null },
    options:      { type: Array, default: () => ([]) },
    selectable:   { type: Function, default: _option => true },
    reduce:       { type: Function, default: option => option },
    value:        { type: [Object, String, Number, Array], default: null }, // v-model
    multiple:     { type: Boolean, default: false },
    clearable:    { type: Boolean, default: false },
    label:        { type: String, default: "label" }, // name of label property, when options is an array of objects
    placeholder:  { type: String, default: "" },
    disabled:     { type: Boolean, default: false },
    template:     { type: Object, default: null }, // component to render (selected and dropdown) options. slots take precedence
    appendToBody: { type: Boolean, default: false },
  },

  data() {
    return {
      components: {
        Deselect: {
          functional: true,
          name:       "UiSelectDeselect",
          render:     h => h("i", { class: "fa fa-times text-muted" }),
        },
        OpenIndicator: {
          functional: true,
          name:       "UiSelectOpenIndicator",
          render:     h => h("i", { class: "fa fa-caret-down text-muted" }),
        },
      },
    }
  },

  computed: {
    selected: {
      get() {
        return this.value
      },
      set(val) {
        this.$emit("input", val)
      },
    },
  },
}
</script>
