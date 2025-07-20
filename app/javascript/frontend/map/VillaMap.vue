<template>
  <div ref="map" class="map" />
</template>

<script>
import { fetchMapData } from "./map"
import poi from "./poi.png"

export default {
  name: "VillaMap",

  props: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },

  mounted() {
    fetchMapData(`${location.pathname}/map`, this.initMap)
  },

  methods: {
    /** @param {google.maps} maps see https://developers.google.com/maps/documentation/javascript/reference */
    initMap(maps) {
      const isTouch = ("ontouchstart" in window),
            { lat, lng } = this,
            center = { lat, lng }

      const map = new maps.Map(this.$refs.map, {
        zoom:            14,
        tilt:            0, // disable tilt, see intervillas/support#520
        center,
        mapTypeId:       maps.MapTypeId.ROADMAP,
        mapTypeControl:  true,
        gestureHandling: isTouch ? "cooperative" : "greedy",
        styles:          [{
          featureType: "poi.business",
          elementType: "all",
          stylers:     [{ visibility: "off" }],
        }],
      })

      new maps.Marker({
        map,
        position: center,
        icon:     { url: poi },
      })
    },
  },
}
</script>
