<template>
  <svg
      class="progress-placeholder"
      xmlns="http://www.w3.org/2000/svg"
      version="1.1"
      :width="width"
      :height="height"
      :viewBox="`0 0 ${width} ${height}`"
  >
    <image
        v-if="upload.preview"
        :height="height"
        :width="width"
        :href="upload.preview"
    />
    <rect
        v-else
        :height="height"
        :width="width"
        fill="#d7d7d6"
    />
    <rect
        :height="height"
        :width="Math.round(width * ratio)"
        fill="#75c5cf"
        :style="{ opacity: upload.preview ? 0.5 : 1 }"
    />
    <text class="progress-info">
      <tspan
          :x="width/2"
          :y="height/2 - 5"
          v-text="humanFilesize"
      />
      <tspan
          :x="width/2"
          :y="height/2 + 15"
          v-text="humanPercentage"
      />
    </text>
  </svg>
</template>

<script>
import { thumbnailWidth, thumbnailHeight } from "./config"

const filesize = (function(units) {
  const factors = units.map((_, i) => Math.pow(1000, i))

  return size => {
    const i = factors.findIndex(f => size < 900 * f),
          s = (size / factors[i]).toFixed(1)
    return `${s} ${units[i]}`
  }
}(["Byte", "KB", "MB", "GB"]))

export default {
  props: {
    upload: { type: Object, required: true },
    width:  { type: Number, default: thumbnailWidth },
    height: { type: Number, default: thumbnailHeight },
  },

  computed: {
    humanFilesize() {
      return filesize(this.upload.bytesTotal)
    },

    humanPercentage() {
      const p = Math.floor(this.ratio * 100)
      return `${p} %`
    },

    ratio() {
      return this.upload.bytesUploaded / this.upload.bytesTotal
    },
  },
}
</script>

<style>
  .progress-placeholder .progress-info {
    text-align: center;
    text-anchor: middle;
    text-shadow: 0 0 7px #000;
    fill: #fff;
  }
</style>
