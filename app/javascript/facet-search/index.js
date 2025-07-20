import Vue from "vue"
import VillaFacetSearch from "./VillaFacetSearch.vue"
import GotoSearchResults from "./GotoSearchResults.vue"
import DisplaySearchResults from "./DisplaySearchResults.vue"
import { awaitSpecialDates } from "../intervillas-drp/special-dates"

const bus = new Vue({ name: "SearchBus" })

const searchResultUpdater = {
  "goto-search-results":    GotoSearchResults, // für die Start-Seite, leitet zu /villas/search um
  "display-search-results": DisplaySearchResults, // für /villas bzw. /villas/search
}

const mountUpdater = (updater, node) => {
  const results = new Vue(updater).$mount(node)

  // search → results
  bus.$on("ready", filterData => {
    results.ready(filterData)
  })
  bus.$on("changeFilter", filterData => {
    results.update(filterData)
  })
  bus.$on("afterPopState", filterData => {
    results.afterPopState(filterData)
  })

  // results → search
  results.$on("updateAvailableVillas", villaIDs => {
    bus.$emit("updateAvailableVillas", villaIDs)
  })
}

const mountSearch = node => {
  const search = new Vue(VillaFacetSearch).$mount(node)

  // search → results
  search.$on("changeFilter", filterData => {
    bus.$emit("changeFilter", filterData)
  })
  search.$on("ready", filterData => {
    bus.$emit("ready", filterData)
  })

  // results → search
  bus.$on("updateAvailableVillas", villaIDs => {
    search.updateAvailableVillas(villaIDs)
  })

  window.addEventListener("popstate", ev => {
    search._setFilterData(ev.state || {})
    bus.$emit("afterPopState", search._getFilterData())
  })
}

document.addEventListener("DOMContentLoaded", () => {
  Object.keys(searchResultUpdater).forEach(key => {
    const updater = searchResultUpdater[key]

    document.querySelectorAll(key).forEach(node => {
      awaitSpecialDates().then(() => {
        mountUpdater(updater, node)
      })
    })
  })

  document.querySelectorAll("villa-facet-search").forEach(node => {
    awaitSpecialDates().then(() => {
      mountSearch(node)
    })
  })
})
