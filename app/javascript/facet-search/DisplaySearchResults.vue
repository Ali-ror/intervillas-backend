<template>
  <div v-if="state === 'init'" class="facet-search-result hidden" />

  <div v-else-if="state === 'loading'" class="facet-search-result text-center">
    <i class="fa fa-2x fa-spinner fa-pulse text-muted" />
  </div>

  <div v-else-if="state === 'finished'" class="facet-search-result">
    <h2 class="lined-heading">
      <span v-if="count === 0">
        {{ "facets.results.zero" | translate }}
      </span>
      <span v-else-if="count === 1">
        {{ "facets.results.one" | translate }}
      </span>
      <span v-else>
        {{ "facets.results.other" | translate({ count }) }}
      </span>
    </h2>
    <div class="room-grid">
      <TeaserVilla
          v-for="villa in activeVillas"
          :key="villa.id"
          v-bind="villa"
      />
    </div>
  </div>

  <div v-else class="facet-search-result">
    ???
  </div>
</template>

<script>
import Filter from "./filter"
import TeaserVilla from "./TeaserVilla.vue"
import URI from "urijs/src/URI"
import Utils from "../intervillas-drp/utils"
import { normalizeVilla } from "./normalize"

export default {
  components: {
    TeaserVilla,
  },

  data() {
    return {
      url:    null,
      method: "POST", // HTTP verb

      filterData: new Filter(), // previously applied filter
      villas:     [], // list of Villa instances

      state:      "init",
      haveVillas: Promise.reject(new Error("uninitialized")).catch(() => {}),
    }
  },

  computed: {
    activeVillas() {
      return this.villas.filter(v => v.visible)
    },

    count() {
      return this.activeVillas.length
    },
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
    ready(filterData) {
      this.filterData = filterData
      this.reload(false)
    },

    /** afterPopState event listener. Is called externally from the search bus. */
    afterPopState(filterData) {
      this.haveVillas.then(() => {
        this.filterData = filterData
        this.applyFilter(false)
      })
    },

    /** Update event listener. Is called externally from the search bus. */
    update(filterData) {
      if (this.requiresReload(filterData)) {
        this.filterData = filterData
        this.reload(true)
      } else {
        this.haveVillas.then(() => {
          this.filterData = filterData
          this.applyFilter(true)
        })
      }
    },

    /**
     * Fetches a new set of villas from the server.
     *
     * @param {Boolean} pushState Whether to setup a new History entry
     */
    reload(pushState) {
      if (this.method !== "POST") {
        throw new Error(`method ${this.method} not supported yet`)
      }

      const params = this.filterData.toParams()
      this.state = "loading"

      this.haveVillas = Utils.postJSON(this.url, params)
        .then(data => {
          const villaIDs = []
          this.villas.splice(0)
          for (let i = 0, len = data.villas.length; i < len; ++i) {
            const v = normalizeVilla(data.villas[i], data.labels)
            v.visible = false

            this.villas.push(v)
            villaIDs.push(v.id)
          }

          this.applyFilter(pushState)
          this.state = "finished"
          this.$emit("updateAvailableVillas", villaIDs)
        })
        .catch(err => {
          this.state = "error"
        })
    },

    /**
     * Compares a Filter against the previous filter state and decides
     * whether we need to fetch a new set of villas.
     *
     * @param {Filter} curr
     * @returns Boolean
     */
    requiresReload(curr) {
      const prev = this.filterData
      return prev.startDate !== curr.startDate
        || prev.endDate !== curr.endDate
        || prev.numPeople !== curr.numPeople
        || prev.numRooms !== curr.numRooms
    },

    /**
     * Applies the current filter to the list of villas.
     *
     * @param {Boolean} pushState Whether to create a new History entry
     */
    applyFilter(pushState) {
      const active = this.filterData.activeVillaIDs
      for (let i = 0, len = this.villas.length; i < len; ++i) {
        const villa = this.villas[i]
        villa.visible = active.includes(villa.id)
      }

      const params = this.filterData.toParams(),
            query = `?${URI.buildQuery(params)}`,
            f = pushState ? "pushState" : "replaceState"
      history[f](params, "", query)
    },
  },
}
</script>
