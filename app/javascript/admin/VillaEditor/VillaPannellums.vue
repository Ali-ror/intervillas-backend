<template>
  <AdminMediaGallery v-bind="api.pannellums">
    <h2>Informationen</h2>
    <p>
      Es wird eine einzelne Bild-Datei mit einem Seitenverhältnis von 2:1
      erwartet (also doppelt so breit wie hoch).
    </p>
    <p>
      Als Dateiformat wird JPEG (.jpg bzw. .jpeg) empfohlen. Die Auflösung
      sollte zwischen 1000×500px und 4000×2000px liegen.
    </p>
    <p>
      Das Bild muss eine vorbereitete 360°-Szene (Rektangularprojektion,
      <em>equirectengular</em>) darstellen. Solche Bilder zeichnen sich
      durch deutliche Verzerrungen aus.
    </p>
  </AdminMediaGallery>
</template>

<script>
import Common from "./common"

export default {
  mixins: [Common],
}
</script>
