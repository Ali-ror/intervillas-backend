<template>
  <div class="villas-list" :class="classList">
    <div v-if="state === 'loading'" class="well well-lg text-center">
      <i class="fa fa-2x fa-spinner fa-spin text-muted" />
    </div>
    <div v-else-if="state === 'error'" class="alert alert-danger">
      {{ "villas_list.error" | translate }}
    </div>
    <div v-else class="room-grid">
      <TeaserVilla
          v-for="v in villas"
          :key="v.id"
          v-bind="v"
      />
    </div>
  </div>
</template>

<script>
import TeaserVilla from "../facet-search/TeaserVilla.vue"
import Utils from "../intervillas-drp/utils"
import { has } from "../lib/has"
import { normalizeVilla } from "../facet-search/normalize"

const urls = Object.freeze({
  "top-items": "/api/villas/top.json",
  "with-boat": "/api/villas/with-boat.json",
})

export default {
  components: {
    TeaserVilla,
  },

  data() {
    return {
      classList: [],
      mode:      null,
      limit:     null,
      state:     "loading",
      villas:    [],
    }
  },

  computed: {
    url() {
      if (has(urls, this.mode)) {
        return this.limit && this.limit > 0
          ? `${urls[this.mode]}?limit=${this.limit}`
          : urls[this.mode]
      }
      return false
    },
  },

  beforeMount() {
    this.classList = Array.from(this.$el.classList)
    this.mode = this.$el.getAttribute("mode")
    this.limit = this.$el.getAttribute("limit")
    this.getVillas()
  },

  methods: {
    getVillas() {
      if (!this.url) {
        return
      }

      Utils.fetchJSON(this.url).then(r => {
        this.villas = r.villas.map(v => normalizeVilla(v, r.labels))
        this.state = "finished"
      }).catch(() => {
        this.state = "error"
      })
    },
  },
}
</script>
