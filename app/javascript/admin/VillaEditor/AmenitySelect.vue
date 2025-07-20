<template>
  <div class="form-group">
    <label class="control-label col-sm-4 col-md-12 col-lg-3">{{ category }}</label>
    <div class="col-sm-8 col-md-12 col-lg-9">
      <UiSelect
          :options="options"
          v-model="selected"
          :reduce="option => option.id"
          multiple
          clearable
      />

      <ul v-if="preselected.length" class="list-inline mt-1">
        <li>Villa tags:</li>
        <li
            v-for="p, i in preselected"
            :key="i"
            class="my-1">
          <em class="small rounded bg-light p-1" v-text="p" />
        </li>
      </ul>

      <button
          v-if="defaults.length"
          class="btn btn-default btn-xxs"
          @click.prevent="applyDefaults"
      >
        apply defaults for {{ category.toLocaleLowerCase() }}
      </button>
    </div>
  </div>

</template>

<script>
import UiSelect from "../../components/UiSelect.vue"

export default {
  components: {
    UiSelect,
  },

  props: {
    category:    { type: String, required: true },
    options:     { type: Array, required: true },
    preselected: { type: Array, required: true },
    value:       { type: Array, required: true },
    defaults:    { type: Array, default: () => ([]) },
  },

  computed: {
    selected: {
      get() {
        return this.value
      },
      set(v) {
        this.$emit("input", v)
      },
    },
  },

  methods: {
    applyDefaults() {
      const v = new Set([...this.value, ...this.defaults])
      this.$emit("input", [...v])
    },
  },
}
</script>
