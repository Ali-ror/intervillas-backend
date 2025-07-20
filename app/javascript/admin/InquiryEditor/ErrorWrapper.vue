<template>
  <div>
    <div v-if="errors" :class="{ 'has-error': hasError }">
      <slot />
      <span
          v-if="errors.required === false"
          class="small help-block"
      >{{ t("required") }}</span>
      <span
          v-if="errors.mustNotBeOccupied === false"
          class="small help-block"
      >{{ t("must_not_be_occupied") }}</span>
      <span
          v-if="errors.mustMatchCategory === false"
          class="small help-block"
      >{{ t("must_match_category") }}</span>
      <span
          v-if="errors.requiredSelection === false"
          class="small help-block"
      >{{ t("required_selection") }}</span>
    </div>

    <slot v-else />
  </div>
</template>

<script>
import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "error_wrapper" })

export default {
  name: "ErrorWrapper",

  props: {
    errors: { type: Object, default: () => ({}) },
  },

  computed: {
    hasError() {
      return this.errors.$error
    },
  },

  methods: {
    t,
  },
}
</script>

<style scoped lang="scss">
  .help-block {
    display: none;
  }

  .has-error {
    .help-block {
      display: block;
    }
  }
</style>
