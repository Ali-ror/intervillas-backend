/**
 * Bildschirmbreite in Pixeln, nachdem von zwei Kalendern nebeneinander
 * auf einen Kalender gewechselt wird.
 *
 * @constant {number}
 * @see `$drp-breakpoint` in `/src/index.sass`
 */
const SINGLE_DOUBLE_BREAKPOINT = 550 // in px

export default {
  data() {
    return {
      singleCalendar: this.inline || this.isSingle || document.documentElement.clientWidth <= SINGLE_DOUBLE_BREAKPOINT,
      hOffset:        0,
    }
  },

  methods: {
    /**
     * Reduziert bei zu schmalem Fenster die Doppel-Kalender-Ansicht auf eine Ein-Kalender-Ansicht.
     * @todo Widget verschieben, wenn es aus dem Fenster ragt (getBoundingClientRect)
     */
    onWindowResize() {
      this.singleCalendar = this.inline || this.isSingle || document.documentElement.clientWidth <= SINGLE_DOUBLE_BREAKPOINT
      this.move()
    },

    /**
     * Verschiebt das Widget soweit nach links, dass es wieder ins Fenster
     * passt, sollte es rechts herausragen.
     *
     * Das Widget muss relativ oder absolut positioniert sein.
     */
    move() {
      if (!this.isOpen || this.inline) {
        return
      }

      this.$nextTick(function() {
        const panel = this.$el.querySelector(".panel"),
              arrow = panel.querySelector(".arrow"),
              bb = panel.getBoundingClientRect(),
              w = document.documentElement.clientWidth

        if (bb.right + this.hOffset > w) {
          this.hOffset = Math.ceil(bb.right + this.hOffset - w)
          panel.style.left = `-${this.hOffset}px`
          arrow.style.left = `${9 + this.hOffset}px` // siehe index.sass
        } else {
          this.hOffset = 0
          panel.style.left = null
          arrow.style.left = null
        }
      })
    },
  },

  mounted() {
    this.$nextTick(function() {
      window.addEventListener("resize", this.onWindowResize)
    })
  },

  beforeDestroy() {
    window.removeEventListener("resize", this.onWindowResize)
  },
}
