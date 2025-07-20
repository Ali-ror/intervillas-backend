<template>
  <img
      :src="main"
      :srcset="sources.join(', ')"
      :alt="alt"
      :width="width"
      :height="height"
      :loading="lazy ? 'lazy' : 'eager'"
      @load="$emit('load', $event)"
  >
</template>

<script>
// keep in sync with ImgProxy::SUPPORTED_DPR_VALUES, see app/lib/img_proxy.rb
const SUPPORTED_DPR_VALUES = [1, 2]

export default {
  props: {
    src:    { type: String, required: true },
    alt:    { type: String, default: null },
    width:  { type: [String, Number], default: null },
    height: { type: [String, Number], default: null },
    lazy:   { type: Boolean, default: false },
  },

  computed: {
    main() {
      const { src } = this
      if (/@\dx$/.test(src)) {
        return src.substr(0, src.length - 3)
      }
      return src
    },

    sources() {
      const { main } = this
      return SUPPORTED_DPR_VALUES
        .filter(f => f !== 1)
        .map(f => `${main}@${f}x ${f}x`)
    },
  },
}
</script>
