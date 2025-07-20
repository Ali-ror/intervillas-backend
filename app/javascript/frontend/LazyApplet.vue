<template>
  <Transition name="fade">
    <slot v-if="active" />

    <div
        v-else
        ref="placeholder"
        class="text-center lazy"
    >
      <i class="fa fa-fw fa-3x fa-spinner fa-pulse text-muted" />
    </div>
  </Transition>
</template>

<script>
import { debounce } from "lodash"

export default {
  data() {
    return {
      active:   false,
      onScroll: null, // window scroll handler
    }
  },

  mounted() {
    this.onScroll = debounce(() => {
      const { placeholder } = this.$refs
      if (!placeholder) {
        return // already loaded
      }

      const { top, bottom } = placeholder.getBoundingClientRect(),
            { innerHeight } = window
      if (top > 0 && innerHeight > bottom) {
        this.disableHandler()
        this.active = true
      }
    }, 50)

    window.addEventListener("scroll", this.onScroll)
    setTimeout(this.onScroll, 500)
  },

  beforeDestroy() {
    this.disableHandler()
  },

  methods: {
    disableHandler() {
      if (this.onScroll) {
        window.addEventListener("scroll", this.onScroll)
        this.onScroll = null
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  .lazy {
    opacity: 0.5;
    padding: 50px;
    background: #eee;
    box-shadow: 0 0 15px -5px #666 inset;
  }
  .fade-enter-active, .fade-leave-active {
    transition: opacity .5s
  }
  .fade-enter, .fade-leave-to {
    opacity: 0
  }
</style>
