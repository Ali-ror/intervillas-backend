import { debounce } from "lodash"

export function embedUrl(videoUrl) {
  const url = new URL(videoUrl)
  let vid = null

  switch (url.hostname) {
  case "www.youtube.com":
  case "m.youtube.com":
  case "youtube.com":
    vid = url.searchParams.get("v")
    break
  case "youtu.be": {
    const segments = url.pathname.split("/")
    vid = segments[segments.length - 1]
    break
  }
  }
  if (!vid) {
    return null
  }
  return `https://www.youtube.com/embed/${vid}?rel=0&amp;showinfo=0&amp;autoplay=1`
}

const dim = () => ({
  w: Math.max(document.documentElement.clientWidth, window.innerWidth || 0),
  h: Math.max(document.documentElement.clientHeight, window.innerHeight || 0),
})

export const reflowMixin = {
  data() {
    return {
      dimensions: dim(),
    }
  },

  computed: {
    modalProps() {
      const { w, h } = this.dimensions,
            aspect = 16 / 9,
            padding = w > 991 ? 100 : w > 768 ? 50 : 0,
            pad = v => v - padding

      return {
        "adaptive":   true,
        "min-width":  560,
        "min-height": 315,
        "width":      Math.floor(w >= h ? pad(h) * aspect : pad(w)),
        "height":     Math.floor(w >= h ? pad(h) : pad(w) / aspect),
        "max-width":  pad(w),
        "max-height": Math.floor(pad(w) / aspect),
      }
    },
  },

  beforeMount() {
    window.addEventListener("resize", this.reflow)
  },

  beforeDestroy() {
    window.removeEventListener("resize", this.reflow)
  },

  methods: {
    reflow: debounce(function() {
      this.dimensions = dim()
    }, 200),
  },
}
