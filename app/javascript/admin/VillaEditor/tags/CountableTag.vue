<template>
  <div
      class="form-group"
      :class="formGroupClass()"
  >
    <label class="control-label col-sm-2">{{ name }}</label>
    <div class="col-sm-2">
      <input
          v-model.number="value.$model"
          type="number"
          min="0"
          class="form-control"
      >
    </div>
  </div>
</template>

<script>
export default {
  props: {
    name:  { type: String, required: true },
    value: { type: Object, required: true },
  },

  methods: {
    formGroupClass() {
      return {
        "has-error":   this.value.$error,
        "has-warning": !this.value.$error && this.value.$dirty,
      }
    },
  },
}
</script>
