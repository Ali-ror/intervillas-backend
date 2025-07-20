<template>
  <a
      href="#"
      class="d-block small text-muted"
      @click.prevent="prompt"
  >
    <i
        class="fa fa-pencil-square-o"
        :title="t('add_note')"
    />
    <em v-if="!value" v-text="t('add_note')" />
    {{ value }}
  </a>
</template>

<script>
import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "price_table.clearing_item" })

export default {
  props: {
    value: { type: String, default: null },
  },

  methods: {
    t,

    prompt() {
      const input = prompt(t("add_note_prompt"), this.value || "")

      if (input !== null) {
        this.$emit("input", input)
      }
    },
  },
}
</script>
