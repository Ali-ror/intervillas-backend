<template>
  <div v-if="loading" class="map d-flex justify-content-center align-items-center">
    <i class="fa fa-spinner fa-pulse fa-4x text-muted" />
  </div>

  <div v-else class="d-flex align-items-stretch gap-3 m-3 ">
    <div class="d-md-flex flex-column hidden-xs hidden-sm map" style="width: 300px">
      <form class="mb-3" @submit.prevent>
        <div class="input-group">
          <div class="input-group-addon">
            <i class="fa fa-search" />
          </div>
          <input
              v-model.trim="searchInput"
              class="form-control"
              :disabled="villas.length === 0"
          >
          <div v-if="searchInput" class="input-group-btn">
            <button
                type="reset"
                class="btn btn-default"
                @click="searchInput = null"
            >
              <i class="fa fa-times" />
            </button>
          </div>
        </div>
      </form>

      <div class="list-group flex-grow-1" style="overflow: scroll">
        <div v-if="villas.length > 0 && matchingVillas.length === 0" class="list-group-item">
          <em class="text-muted">no matches</em>
        </div>
        <a
            v-for="v in matchingVillas"
            :key="v.id"
            ref="villaLinks"
            :href="v.url"
            :class="{ active: active === v.id }"
            class="list-group-item d-flex align-items-center"
            @click.prevent="setActive(v.idx)"
        >
          <span v-text="v.name" />
          <i v-if="active === v.id" class="fa fa-lg fa-caret-right ml-auto" />
        </a>
      </div>
    </div>

    <div class="flex-grow-1">
      <div ref="map" class="map overview-map" />
    </div>

    <div class="hidden">
      <div ref="teaser">
        <template v-if="active">
          <TeaserVilla v-bind="activeVilla"/>

          <div class="text-center border-top border-light mt-3 pt-1">
            <a
                href="#"
                class="btn btn-default btn-sm"
                @click.prevent="zoomTo(activeVilla)"
            >
              <template v-if="zoom < 19">
                <i class="fa fa-fw fa-search-plus" />
                {{ t("zoom_in") }}
              </template>
              <template v-else>
                <i class="fa fa-fw fa-search-minus" />
                {{ t("show_surrounding") }}
              </template>
            </a>

            <a
                :href="activeVilla.searchUrl"
                class="btn btn-default btn-sm"
            >
              <i class="fa fa-fw fa-arrow-right" />
              {{ t("more") }}
            </a>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
import TeaserVilla from "../../facet-search/TeaserVilla.vue"
import { normalizeVilla } from "../../facet-search/normalize"
import { fetchMapData, ClusterRenderer } from "./map"
import { MarkerClusterer, SuperClusterAlgorithm } from "@googlemaps/markerclusterer"
import Fuse from "fuse.js"
import { translate } from "@digineo/vue-translate"

import poi from "./poi.png"
import poiLabeled from "./poi-labeled.png"

/**
 * Notes:
 * - this.villas is empty until fetchMapData has loaded the Maps API client
 * - non-reactive Map API client models:
 *   - this._map     → google.maps.Map
 *   - this._info    → google.maps.InfoWindow for <TeaserVilla />
 *   - this._markers → array of google.maps.Marker
 * - to get to a marker for a villa, use this._markers[this.villas[i].idx]
 */
export default {
  name: "OverviewMap",

  components: {
    TeaserVilla,
  },

  data() {
    return {
      loading: true,

      villas:      [],
      labels:      {},
      active:      null, // villa ID
      searchInput: null,

      origin: {
        lat: 26.62364,
        lng: -81.98729,
      },
      zoom: 12, // updated by _map event
    }
  },

  computed: {
    activeVilla() {
      const { active, villas } = this
      return villas.find(v => v.id === active)
    },

    matchingVillas() {
      const { searchInput, villas } = this
      if (!searchInput) {
        return villas
      }
      return this.fuse()
        .search(searchInput)
        .map(result => result.item)
    },
  },

  watch: {
    matchingVillas() {
      this.updateMarkers()
    },

    active(id) {
      if (id) {
        const i = this.matchingVillas.findIndex(v => v.id === id)
        this.$refs.villaLinks[i].scrollIntoView({ block: "nearest" })

        if (this._map) {
          const { lat, lng, idx } = this.matchingVillas[i]
          const marker = this._markers[idx]

          this._info.open(this._map, marker)
          this._map.panTo({ lat, lng })
          this.updateMarkers()
        }
        return
      }
      if (this._map) {
        if (!id) {
          this._info.close()
        }

        this._map.setZoom(12)
        this._map.panTo(this.origin)
        this.updateMarkers()
      }
    },

    zoom(newVal, oldVal) {
      const threshold = 14
      if ((newVal < threshold && threshold <= oldVal) || (newVal >= threshold && threshold > oldVal)) {
        this.updateMarkers()
      }
    },
  },

  async mounted() {
    const { villas, labels } = await fetchMapData(location.pathname, this.initMap)

    this.labels = labels
    this.villas = villas.map(villa => {
      const v = normalizeVilla(villa, labels)
      v.idx = null
      return v
    }).sort((a, b) => a.name.localeCompare(b.name))

    this._fuse = new Fuse(this.villas, {
      keys:               ["name"],
      findAllMatches:     true,
      minMatchCharLength: 2,
    })

    this.loading = false
  },

  methods: {
    t(key) {
      return translate(key, { scope: "maps" })
    },

    fuse() {
      return this._fuse
    },

    setActive(idx) {
      const { id } = this.villas.find(v => v.idx === idx)
      this.active = id
    },

    zoomTo({ lat, lng }) {
      this._map.panTo({ lat, lng })
      this._map.setZoom(this.zoom < 19 ? 19 : 12)
    },

    /** @param {google.maps} maps see https://developers.google.com/maps/documentation/javascript/reference */
    initMap(maps) {
      const isTouch = ("ontouchstart" in window)

      const map = new maps.Map(this.$refs.map, {
        zoom:            12,
        center:          this.origin,
        mapTypeId:       maps.MapTypeId.SATELLITE,
        mapTypeControl:  false,
        gestureHandling: isTouch ? "cooperative" : "greedy",
        styles:          [{
          featureType: "poi.business",
          elementType: "all",
          stylers:     [{ visibility: "off" }],
        }],

        // move controls to the left side. the screen on the right is occupied
        // by contact items the live chat widget
        fullscreenControlOptions: { position: maps.ControlPosition.LEFT_TOP },
        panControlOptions:        { position: maps.ControlPosition.LEFT_BOTTOM },
        rotateControlOptions:     { position: maps.ControlPosition.LEFT_BOTTOM },
        zoomControlOptions:       { position: maps.ControlPosition.LEFT_BOTTOM },
        streetViewControlOptions: { position: maps.ControlPosition.LEFT_BOTTOM },
      })
      this._map = map
      this._cluster = new MarkerClusterer({
        map,
        algorithm: new SuperClusterAlgorithm({ radius: 100 }),
        renderer:  new ClusterRenderer(maps, "#fff", "#75c5cf"),
      })

      map.addListener("click", () => this._info.close())
      map.addListener("zoom_changed", () => this.zoom = map.getZoom())

      this._markers = []

      for (let i = 0, len = this.villas.length; i < len; ++i) {
        const villa = this.villas[i],
              { lat, lng, name } = villa
        villa.idx = i
        villa.shortName = name.replace(/^Villa\s+/, "")

        const marker = new maps.Marker({
          position: { lat, lng },
          icon:     { url: poi },
        })
        this._markers.push(marker)

        maps.event.addListener(marker, "click", () => {
          this.setActive(i)
          this._info.open(this._map, marker)
        })
      }

      this._info = new maps.InfoWindow({
        content:     this.$refs.teaser,
        pixelOffset: { width: 0, height: 45 },
      })

      this.updateMarkers()
    },

    updateMarkers() {
      if (!this._map) {
        return
      }

      const zoomThresholdReached = this.zoom < 14
      for (let i = this.villas.length - 1; i >= 0; --i) {
        const villa = this.villas[i],
              { id, idx, shortName } = villa,
              active = this.active === id,
              marker = this._markers[idx],
              matchesSearch = this.matchingVillas.includes(villa)
        marker.setLabel(zoomThresholdReached
          ? null
          : {
            text:      shortName,
            className: "villa-marker",
          })
        marker.setMap(matchesSearch ? this._map : null)
        marker.setIcon(zoomThresholdReached ? poi : poiLabeled)
        marker.setZIndex(active ? 500 : null)
        if (matchesSearch) {
          this._cluster.addMarker(marker, false)
        } else {
          this._cluster.removeMarker(marker, false)
        }
      }

      this._cluster.renderer.setColors("#fff", zoomThresholdReached ? "#75c5cf" : "#528a90")
      this._cluster.render()
    },
  },
}
</script>

<style lang="scss">
  .map.overview-map {
    min-height: 70vh;

    .room-thumb {
      box-shadow: none;

      .ident a::after {
        display: none;
      }

      a:focus {
        outline: none !important;
      }
    }

    .villa-marker {
      color: #fff !important;
      background-color: #528a90;
      font-size: inherit !important;
      font-family: inherit !important;
      border-radius: 1px;
      padding: 4px 6px;
    }
  }
</style>
