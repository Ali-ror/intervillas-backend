<template>
  <div v-if="changes.length" class="alert alert-warning mt-3">
    <p v-text="t('heading')" />

    <ul class="my-3">
      <li v-for="(chg, i) in changes" :key="i">
        <s v-if="skip" v-text="chg" />
        <span v-else v-text="chg" />
      </li>
    </ul>

    <ToggleSwitch :active="skip" @click="$emit('change')">
      {{ t('skip') }}
    </ToggleSwitch>
  </div>
</template>

<script>
import { translate } from "@digineo/vue-translate"
import ToggleSwitch from "../ToggleSwitch.vue"
const t = (key, rentable = null) => rentable
  ? translate(key, { scope: `inquiry_editor.note_mail.${rentable}` })
  : translate(key, { scope: "inquiry_editor.note_mail" })

export default {
  components: {
    ToggleSwitch,
  },

  props: {
    villa: { type: String, default: null },
    boat:  { type: String, default: null },
    skip:  { type: Boolean, default: false },
  },

  computed: {
    changes() {
      const changes = []
      if (this.villa) {
        changes.push(t(this.villa, "villa"))
      }
      if (this.boat) {
        changes.push(t(this.boat, "boat"))
      }
      return changes
    },
  },

  methods: {
    t,
  },
}
</script>
