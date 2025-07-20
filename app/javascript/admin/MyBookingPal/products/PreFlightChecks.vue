<template>
  <ul class="fa-ul">
    <li v-for="result, key in checks" :key="key">
      <template v-if="result === null">
        <i class="fa fa-li fa-circle-o text-muted"/>
        <p class="text-muted">
          {{ t("skipped") }}: {{ title(key) }}
        </p>
        <p class="small" v-text="description(key)"/>
      </template>
      <template v-else-if="result === true">
        <i class="fa fa-li fa-check text-success"/>
        <p class="text-success">
          {{ t("success") }}: {{ title(key) }}
        </p>
      </template>
      <template v-else-if="result === false">
        <i class="fa fa-li fa-times text-danger"/>
        <p class="text-danger">
          {{ t("failure") }}: {{ title(key) }}
        </p>
        <p class="small" v-text="description(key)"/>
      </template>
    </li>
  </ul>
</template>

<script>
import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "admin.villa_check" })

export default {
  props: {
    checks: { type: Array, required: true },
  },

  methods: {
    t,

    title(key) {
      return t(`checks.${key}.title`)
    },

    description(key) {
      return t(`checks.${key}.description`)
    },
  },
}
</script>
