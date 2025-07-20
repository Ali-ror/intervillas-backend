<template>
  <div ref="placeholder" class="mt-4">
    <h3>Hilfe</h3>
    <i class="fa fa-4x text-muted pull-left" />
    <p>
      Im Formular auf die <i class="fa fa-question-circle text-info" />-Icons
      klicken, um detailliertere Informationen zu erhalten.
    </p>

    <div v-if="help" :style="{ position: 'fixed', width: `${width}px` }">
      <a
          href="#"
          class="pull-right close"
          @click="setHelp(null)"
      >
        <i class="fa fa-times" />
      </a>
      <h3 v-text="title" />
      <template v-if="isHTML">
        <!-- eslint-disable vue/no-v-html -->
        <p
            v-for="(text, i) in paragraphs"
            :key="i"
            v-html="text"
        />
        <!-- eslint-enable vue/no-v-html -->
      </template>
      <template v-else>
        <p
            v-for="(text, i) in paragraphs"
            :key="i"
            v-text="text"
        />
      </template>
    </div>
  </div>
</template>

<script>
import { has } from "../../lib/has"
import { HELP } from "./_texts"
import { mapState, mapMutations } from "vuex"

export default {
  data() {
    return {
      width: null,
    }
  },

  computed: {
    ...mapState(["help"]),

    helpObject() {
      if (this.help && has(HELP, this.help)) {
        return HELP[this.help]
      }
      return null
    },

    title() {
      if (this.helpObject) {
        return this.helpObject.title
      }
      return null
    },

    paragraphs() {
      if (this.helpObject) {
        return this.helpObject.desc
      }
      return null
    },

    isHTML() {
      if (this.helpObject) {
        return !!this.helpObject
      }
      return null
    },
  },

  mounted() {
    const r = this.$refs.placeholder.getClientRects()[0]
    this.width = r.width
  },

  methods: {
    ...mapMutations(["setHelp"]),
  },
}
</script>
