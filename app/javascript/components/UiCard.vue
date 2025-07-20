<template>
  <div class="panel" :class="`panel-${variant}`">
    <div v-if="collapsible && (heading || $slots.heading)" :class="headerClasses">
      <a
          href="#"
          :class="collapsibleLinkClasses"
          @click="wantOpen = !wantOpen"
      >
        <i class="fa fa-fw" :class="wantOpen ? 'fa-caret-down' : 'fa-caret-right'" />
        <slot name="heading">
          {{ heading }}
        </slot>
      </a>
    </div>
    <div v-else-if="!collapsible && (heading || $slots.heading)" :class="headerClasses">
      <slot name="heading">
        {{ heading }}
      </slot>
    </div>

    <template v-if="noBody && (!collapsible || wantOpen)">
      <slot />
    </template>
    <div v-else :class="bodyClasses">
      <slot />
    </div>

    <div v-if="footer || $slots.footer" :class="footerClasses">
      <slot name="footer">
        {{ footer }}
      </slot>
    </div>
  </div>
</template>

<script>
function mergeClasses(...classes) {
  const result = new Set()
  for (let i = 0, ilen = classes.length; i < ilen; ++i) {
    let curr = classes[i]

    // first, convert to array
    if (curr == null) {
      curr = []
    } else if (typeof curr === "string" || curr instanceof String) {
      // split on whitespace
      curr = curr.split(/\s+/)
    } else if (typeof curr === "object" && !Array.isArray(curr)) {
      // collect keys where the corresponding value is truthy
      curr = Object.entries(curr).filter(([_, v]) => !!v).map(([k, _]) => k)
    }
    // add keys to result set (i.e. discard duplicates)
    for (let j = 0, jlen = curr.length; j < jlen; ++j) {
      result.add(curr[j])
    }
  }
  return [...result]
}

export default {
  props: {
    heading:     { type: String, default: null },
    noBody:      { type: Boolean, default: false },
    footer:      { type: String, default: null },
    variant:     { type: String, default: "default" },
    headerClass: { type: [String, Array, Object], default: null },
    footerClass: { type: [String, Array, Object], default: null },
    bodyClass:   { type: [String, Array, Object], default: null },
    collapsible: { type: Boolean, default: false },
    open:        { type: Boolean, default: false },
  },

  data() {
    return {
      wantOpen: this.open,
    }
  },

  computed: {
    headerClasses() {
      return mergeClasses(this.headerClass, ["panel-heading"])
    },
    collapsibleLinkClasses() {
      const variant = this.variant !== "default"
        ? [`text-${this.variant}`]
        : null
      return mergeClasses(["d-flex", "justify-content-start", "align-items-baseline"], variant)
    },
    bodyClasses() {
      return mergeClasses(this.bodyClass, ["panel-body"], {
        "d-none": this.collapsible && !this.wantOpen,
      })
    },
    footerClasses() {
      return mergeClasses(this.footerClass, ["panel-footer"])
    },
  },

  watch: {
    open(val) {
      this.wantOpen = val
      this.$emit(val ? "open" : "close")
    },
  },
}
</script>
