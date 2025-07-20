<template>
  <form
      class="form-horizontal"
      @submit.prevent="$emit('save')"
  >
    <h3>Bewertung bearbeiten</h3>

    <div
        class="form-group"
        :class="{ 'has-warning': $v.review.name.$dirty }"
    >
      <label class="control-label col-sm-3">Name</label>
      <div class="col-sm-9 col-lg-6">
        <input
            v-model="$v.review.name.$model"
            type="text"
            class="form-control"
        >
      </div>
    </div>

    <div
        class="form-group"
        :class="{ 'has-warning': $v.review.city.$dirty }"
    >
      <label class="control-label col-sm-3">Ort</label>
      <div class="col-sm-9 col-lg-6">
        <input
            v-model="$v.review.city.$model"
            type="text"
            class="form-control"
        >
      </div>
    </div>

    <div
        class="form-group"
        :class="{ 'has-warning': $v.review.rating.$dirty }"
    >
      <label class="control-label col-sm-3">Bewertung</label>
      <div class="col-sm-9 col-lg-6">
        <input
            v-model.number="$v.review.rating.$model"
            type="number"
            min="0"
            max="5"
            step="1"
            class="form-control"
        >
      </div>
    </div>

    <div
        class="form-group"
        :class="{ 'has-warning': $v.review.text.$dirty }"
    >
      <label class="control-label col-sm-3">Text</label>
      <div class="col-sm-9 col-lg-6">
        <textarea
            v-model.trim="$v.review.text.$model"
            rows="10"
            class="form-control"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-sm-9 col-lg-6 col-sm-offset-3">
        <button
            class="btn"
            :class="$v.$anyDirty ? 'btn-primary' : 'btn-default'"
            type="button"
            @click.prevent="$emit('save')"
        >
          Speichern
        </button>

        <button
            class="btn btn-default"
            type="button"
            @click.prevent="$emit('cancel')"
        >
          Abbrechen
        </button>
      </div>
    </div>
  </form>
</template>

<script>
import { validationMixin } from "vuelidate"

export default {
  mixins: [validationMixin],

  props: {
    review: { type: Object, required: true },
  },

  validations() {
    return {
      review: {
        name:   {},
        city:   {},
        rating: {},
        text:   {},
      },
    }
  },
}
</script>
