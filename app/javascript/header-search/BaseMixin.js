import { debounce } from "lodash"

export default {
  data() {
    return {
      villas:      [],
      activeIndex: 0,
      input:       "",
    }
  },

  watch: {
    input(newVal) {
      this.emitSearchEventThrottled()
    },

    villas(newVal) {
      this.activeIndex = 0
    },
  },

  methods: {
    emitSearchEventThrottled: debounce(function() {
      const val = this.input.toString().trim()
      if (val === "") {
        this.villas = null
      } else {
        this.$emit("search", val)
      }
    }, 250),

    clear() {
      this.input = ""
      this.$emit("clear")
    },

    setActive(dir) {
      if (!this.villas) {
        this.activeIndex = 0
        return
      }

      this.activeIndex = (this.activeIndex + dir) % this.villas.length
      if (this.activeIndex < 0) {
        this.activeIndex = this.villas.length - 1
      }
    },

    followActive() {
      if (this.villas && this.activeIndex < this.villas.length) {
        window.location.href = this.villas[this.activeIndex].path
      }
    },
  },
}
