<template>
  <div class="facet-search-result hidden" />
</template>

<script>
import URI from "urijs/src/URI"

export default {
  name: "GotoSearchResults",

  data() {
    return {
      url:    null,
      method: "GET", // HTTP verb
    }
  },

  beforeMount() {
    const ds = this.$el.dataset
    this.url = URI(ds.url)

    if (ds.method) {
      this.method = ds.method.toUpperCase()
    }
  },

  methods: {
    /** Ready event listener. Is called externally from the search bus. */
    ready(_filterData) {
      return
    },

    /** afterPopState event listener. Is called externally from the search bus. */
    afterPopState(_filterData) {
      return
    },

    /** Update event listener. Is called externally from the search bus. */
    update(filterData) {
      if (this.method === "GET") {
        const params = filterData.toParams()
        window.location.href = this.url.search(params).toString()
      } else {
        throw new Error(`method ${this.method} not supported yet`)
      }
    },
  },
}
</script>
