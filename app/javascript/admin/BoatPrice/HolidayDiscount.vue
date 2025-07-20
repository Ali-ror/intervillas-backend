<template>
  <div
      class="panel panel-default mb-0"
      :class="formId"
  >
    <div
        class="panel-heading d-flex justify-content-start align-items-center gap-1"
        title="ungespeichert"
    >
      <i v-if="discount._dirty" class="fa fa-save text-warning" />
      <s v-if="discount.destroy" v-text="discount.label" />
      <span v-else v-text="discount.label" />

      <button
          v-if="discount.destroy"
          type="button"
          class="btn btn-warning btn-xxs ml-auto"
          @click="discount.destroy = false"
      >
        <i class="fa fa-refresh" />
        behalten
      </button>
      <button
          v-else-if="discount.persisted || discount._dirty"
          type="button"
          class="btn btn-danger btn-xxs ml-auto"
          @click="discount.destroy = true"
      >
        <i class="fa fa-trash" />
        löschen
      </button>
    </div>

    <div class="panel-body">
      <div class="form-group">
        <label :for="`${formId}_percent`" class="control-label col-sm-5">
          Aufschlag
        </label>
        <div class="col-sm-7">
          <div class="input-group">
            <input
                :id="`${formId}_percent`"
                v-model.number="discount.percent"
                type="number"
                class="form-control"
                :disabled="discount.destroy"
                min="0"
                step="1"
            >
            <span class="input-group-addon">
              <i class="fa fa-percent" />
            </span>
          </div>
        </div>
      </div>

      <div class="form-group">
        <label :for="`${formId}_days_before`" class="control-label col-sm-5">
          Tage vorher
        </label>
        <div class="col-sm-7">
          <input
              :id="`${formId}_days_before`"
              v-model.number="discount.before"
              type="number"
              class="form-control"
              :disabled="discount.destroy"
              min="0"
              step="1"
          >
        </div>
      </div>

      <div class="form-group">
        <label :for="`${formId}_days_after`" class="control-label col-sm-5">
          Tage danach
        </label>
        <div class="col-sm-7">
          <input
              :id="`${formId}_days_after`"
              v-model.number="discount.after"
              type="number"
              class="form-control"
              :disabled="discount.destroy"
              min="0"
              step="1"
          >
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { Discount } from "./models"

export default {
  props: {
    value: { type: Discount, required: true }, // v-model
  },

  computed: {
    discount: {
      get() {
        return this.value
      },
      set(val) {
        this.$emit("input", val)
      },
    },

    formId() {
      return `boat_holiday_discount_${this.discount.description}`
    },
  },
}
</script>
