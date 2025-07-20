<template>
  <UiSelect
      :placeholder="placeholder"
      :options="options"
      :selectable="o => !o.header"
      :value="selected"
      @input="onSelect"
  >
    <template #selected-option="{ label }">
      {{ label }}
    </template>
    <template #option="{ header, label }">
      <strong
          v-if="header"
          class="small"
          v-text="label"
      />
      <span v-else v-text="label" />
    </template>
  </UiSelect>
</template>

<script>
import UiSelect from "../components/UiSelect.vue"

const toOptions = (header, items) => {
  if (!items.length) {
    return []
  }
  return items.reduce((list, [id, label]) => {
    list.push({ id, label })
    return list
  }, [{ label: header, header: true }])
}

export default {
  components: {
    UiSelect,
  },

  props: {
    placeholder: { type: String, default: "" },
    boats:       { type: Array, default: () => ([]) },
    villas:      { type: Array, default: () => ([]) },
  },

  computed: {
    options() {
      return [
        ...toOptions("Villen", this.villas),
        ...toOptions("Boote", this.boats),
      ]
    },

    selected() {
      const { pathname: s } = location

      return this.options.find(o => o.id === s) ?? null
    },
  },

  methods: {
    onSelect(val) {
      location.assign(val.id)
    },
  },
}
</script>
