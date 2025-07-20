<template>
  <AdminMediaGallery v-bind="api.tours" :accepted-files="['.zip']">
    <h2>Informationen</h2>
    <p>
      Touren (v1) sind "Micro-Sites" der Fa. SWFL360 LLC. Diese Micro-Sites
      werden als ZIP-Datei exportiert und enthalten eine oder mehrere
      "Szenen" (360&deg;-Ansichten).
    </p>
    <p>
      Pro "Szene" darf die ZIP-Datei etwa 6 MB groß sein (also ~24 MB, wenn
      vier Szenen enthalten sind). Die ZIP-Datei muss eine Datei mit dem
      Namen <code>tour.html</code> beinhalten.
    </p>
  </AdminMediaGallery>
</template>

<script>
import Common from "./common"

export default {
  mixins: [Common],
}
</script>
