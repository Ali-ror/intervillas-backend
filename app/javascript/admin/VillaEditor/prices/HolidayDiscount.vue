<template>
  <div :class="panelClass">
    <div class="panel-heading">
      {{ title }}
      <small v-if="subtitle" class="text-muted">
        ({{ subtitle }})
      </small>
    </div>

    <div
        v-if="value.$model"
        class="form-group"
        :class="formGroupClass('percent')"
    >
      <label class="control-label col-sm-6" :for="`${idPrefix}_percent`">
        Aufschlag
      </label>
      <div class="col-sm-6">
        <div class="input-group input-group-sm">
          <input
              :id="`${idPrefix}_percent`"
              v-model.number="value.percent.$model"
              :disabled="value.$model._destroy"
              type="number"
              min="0"
              step="1"
              class="form-control"
          >
          <span class="input-group-addon">
            <i class="fa fa-percent" />
          </span>
        </div>
        <div
            v-for="(e, i) in errorsFor('percent')"
            :key="i"
            class="help-block"
            v-text="e"
        />
      </div>
    </div>

    <div
        v-if="value.$model"
        class="form-group"
        :class="formGroupClass('days_before')"
    >
      <label class="control-label col-sm-6" :for="`${idPrefix}_days_before`">
        Tage vorher
      </label>
      <div class="col-sm-6">
        <input
            :id="`${idPrefix}_days_before`"
            v-model="value.days_before.$model"
            :disabled="value.$model._destroy"
            type="number"
            min="0"
            step="1"
            class="form-control"
        >
        <div
            v-for="(e, i) in errorsFor('days_before')"
            :key="i"
            class="help-block"
            v-text="e"
        />
      </div>
    </div>

    <div
        v-if="value.$model"
        class="form-group"
        :class="formGroupClass('days_after')"
    >
      <label class="control-label col-sm-6" :for="`${idPrefix}_days_after`">
        Tage danach
      </label>
      <div class="col-sm-6">
        <input
            :id="`${idPrefix}_days_after`"
            v-model="value.days_after.$model"
            :disabled="value.$model._destroy"
            type="number"
            min="0"
            step="1"
            class="form-control"
        >
        <div
            v-for="(e, i) in errorsFor('days_after')"
            :key="i"
            class="help-block"
            v-text="e"
        />
      </div>
    </div>

    <div class="panel-footer">
      <button
          v-if="value.$model && !value.$model._destroy"
          type="button"
          class="btn btn-warning"
          @click.prevent="value._destroy.$model = true"
      >
        <i class="fa fa-trash" /> entfernen
      </button>

      <button
          v-else-if="value.$model && value.$model._destroy"
          type="button"
          class="btn btn-default"
          @click.prevent="value._destroy.$model = false"
      >
        <i class="fa fa-undo" /> behalten
      </button>

      <button
          v-else
          type="button"
          class="btn btn-default"
          @click.prevent="$emit('add')"
      >
        <i class="fa fa-plus" /> hinzufügen
      </button>
    </div>
  </div>
</template>

<script>
import { errorsFor } from "../validators"

export default {
  props: {
    value:    { type: Object, required: true },
    title:    { type: String, required: true },
    subtitle: { type: String, default: null },
    idPrefix: { type: String, required: true },
  },

  computed: {
    panelClass() {
      const cls = ["panel"]

      if (this.value.$model) {
        if (this.value.$model._destroy) {
          cls.push("panel-danger")
        } else if (this.value.$model.newRecord) {
          cls.push("panel-success")
        } else {
          cls.push("panel-default")
        }
      } else {
        cls.push("panel-default")
      }
      return cls
    },
  },

  methods: {
    formGroupClass(field) {
      const f = this.value[field]
      return {
        "has-error":   f.$error,
        "has-warning": !f.$error && f.$dirty,
      }
    },

    errorsFor(field) {
      const f = this.value[field]
      return errorsFor("de", f)
    },
  },
}
</script>

<style scoped>
  .panel > .form-group {
    padding: 12px 0;
    margin: 0;
  }
  .panel > .form-group + .form-group {
    padding-top: 0;
    margin-top: -6px;
  }
</style>
