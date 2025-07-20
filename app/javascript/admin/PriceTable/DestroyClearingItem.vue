<template>
  <a
      v-if="value"
      href="#"
      class="small"
      @click.prevent="$emit('input', false)"
  >
    <i class="fa fa-refresh" />
    {{ t("keep") }}
  </a>
  <a
      v-else
      href="#"
      class="small text-danger"
      :title="t('remove')"
      @click.prevent="$emit('input', true)"
  >
    <i class="fa fa-trash text-danger mx-2" />
  </a>
</template>

<script>
import { translate } from "@digineo/vue-translate"

export default {
  props: {
    value: { type: Boolean, default: false },
  },

  methods: {
    t: key => translate(key, { scope: "price_table.clearing_item" }),
  },
}
</script>
