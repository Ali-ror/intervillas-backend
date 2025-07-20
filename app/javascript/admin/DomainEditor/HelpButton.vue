<template>
  <a
      href="#"
      class="ml-2 text-info"
      @click.prevent="setHelp(help === item ? null : item)"
  >
    <i class="fa fa-question-circle" />
  </a>
</template>

<script>
import { mapState, mapMutations } from "vuex"

export default {
  props: {
    item: { type: String, required: true },
  },

  computed: {
    ...mapState(["help"]),
  },

  methods: {
    ...mapMutations(["setHelp"]),
  },
}
</script>
