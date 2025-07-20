<template>
  <div v-if="slides.length" class="gallery">
    <div ref="carousel" class="carousel">
      <Transition :name="slideDirection">
        <a
            :key="active"
            href="#"
            class="slide"
            @click.prevent="onCarouselClick"
        >
          <RetinaImage
              :src="currentImage[bestSize]"
              @load="onImgLoad"
          />
        </a>
      </Transition>

      <nav class="controls">
        <button
            type="button"
            class="controls-prev"
            @click.prevent="--active"
        >
          <i class="fa fa-fw fa-lg fa-chevron-left" />
        </button>

        <button
            type="button"
            class="controls-next"
            @click.prevent="++active"
        >
          <i class="fa fa-fw fa-lg fa-chevron-right" />
        </button>

        <button
            type="button"
            class="controls-exit-fullscreen"
            @click.prevent="toggleFullscreen"
        >
          <i class="fa fa-fw fa-lg fa-times" />
        </button>
      </nav>
    </div>

    <nav v-if="dots" class="dots my-3 mx-5">
      <a
          v-for="(item, i) in slides"
          :key="i"
          href="#"
          :class="{ active: index === i }"
          @click.prevent="active = i"
      >
        <i
            class="fa"
            :class="{
              'fa-circle-o': index !== i,
              'fa-circle': index === i,
            }"
        />
      </a>
    </nav>

    <nav
        v-else
        ref="thumbNav"
        class="thumbnails"
    >
      <div class="wrapper" :style="{ left: `${thumbOffset}px` }">
        <a
            v-for="(item, i) in slides"
            :key="i"
            ref="thumbs"
            href="#"
            :class="{ active: index === i }"
            @click.prevent="active = i"
        >
          <RetinaImage :src="item.thumbnail" lazy />
        </a>
      </div>
    </nav>
  </div>
</template>

<script>
import RetinaImage from "./RetinaImage.vue"
import { debounce } from "lodash"
import { has } from "../lib/has"

const NEXT_SLIDE = Symbol("next-slide"),
      PREV_SLIDE = Symbol("prev-slide"),
      EXIT_FULLSCREEN = Symbol("exit-fullscreen")

// KeyboardEvent.code => Symbol
const KEYBOARD_ACTIONS = {
  ArrowRight: NEXT_SLIDE,
  ArrowDown:  NEXT_SLIDE,
  PageDown:   NEXT_SLIDE,
  Space:      NEXT_SLIDE,

  ArrowLeft: PREV_SLIDE,
  ArrowUp:   PREV_SLIDE,
  PageUp:    PREV_SLIDE,

  Escape: EXIT_FULLSCREEN,
}

export default {
  name: "IntervillasGallery",

  components: {
    RetinaImage,
  },

  props: {
    slides:       { type: Array, required: true },
    dots:         { type: Boolean, default: true },
    noFullscreen: { type: Boolean, default: false },
  },

  data() {
    return {
      active:         0,
      isFullscreen:   false,
      isTouch:        "ontouchstart" in window,
      dragging:       null,
      slideDirection: "left",

      // URL => Number, set on imageLoad
      slideRatios: {},
      windowWidth: window.innerWidth,
      thumbOffset: 0,

      carouselOptions: {
        autoplay:              false, // true,
        adjustableHeight:      true,
        autoplayTimeout:       5000,
        centerMode:            true,
        loop:                  true,
        navigationEnabled:     false,
        paginationEnabled:     this.dots,
        paginationColor:       "#ccc",
        paginationActiveColor: "#333",
        paginationPadding:     5,
        perPage:               1,
      },
    }
  },

  computed: {
    index() {
      let active = this.active
      const len = this.slides.length

      // avoid modulus on negative numbers
      while (active < 0) {
        active += len
      }
      return (len + active) % len
    },

    currentImage() {
      return this.slides[this.index]
    },

    bestSize() {
      if (!this.isFullscreen) {
        return "carousel"
      }
      return this.windowWidth > 1440
        ? "xl"
        : this.windowWidth > 1080
          ? "lg"
          : this.windowWidth > 750
            ? "md"
            : "carousel"
    },
  },

  watch: {
    active(prevVal, newVal) {
      if (prevVal > newVal) {
        this.slideDirection = "left"
      } else {
        this.slideDirection = "right"
      }

      this.$nextTick(this.updateThumbnails)
    },
  },

  mounted() {
    if (!this.slides.length) {
      return // mostly only in tests
    }

    this.$refs.carousel.addEventListener(this.isTouch ? "touchstart" : "mousedown", this.onTouchStart)
    document.addEventListener("keydown", this.onKeydown)
    window.addEventListener("resize", this.onResize)
  },

  beforeUnmount() {
    if (!this.slides.length) {
      return // mostly only in tests
    }

    document.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("resize", this.onResize)
    this.$refs.carousel.removeEventListener(this.isTouch ? "touchstart" : "mousedown", this.onTouchStart)
  },

  methods: {
    onResize: debounce(function() {
      const srcPath = this.currentImage[this.bestSize]
      if (has(this.slideRatios, srcPath)) {
        const ratio = this.slideRatios[srcPath],
              { width } = this.$refs.carousel.getBoundingClientRect()
        this.$refs.carousel.style.height = `${Math.round(width / ratio)}px`
      }

      this.windowWidth = window.innerWidth
      this.updateThumbnails()
    }, 16),

    // img.load callback
    onImgLoad({ target }) {
      const { naturalWidth, naturalHeight } = target,
            ratio = naturalWidth / naturalHeight

      const srcPath = new URL(target.src).pathname // ignore scheme, host, port
      this.$set(this.slideRatios, srcPath, ratio) // remember value

      const { carousel } = this.$refs,
            { width } = carousel.getBoundingClientRect()
      this.$refs.carousel.style.height = `${Math.round(width / ratio)}px`
    },

    // @click handler for <a> wrapper around carousel images. will toggle
    // fullscreen mode, unless inhibited by noFullscreen prop.
    onCarouselClick(ev) {
      if (this.noFullscreen) {
        return
      }

      ev.preventDefault()
      this.toggleFullscreen()
    },

    toggleFullscreen() {
      this.isFullscreen = !this.isFullscreen
      document.body.classList.toggle("fullscreen-gallery")
    },

    onTouchStart(ev) {
      if (ev.button === 2) {
        return // ignore right mouse button
      }

      const { isTouch } = this
      document.addEventListener(isTouch ? "touchend" : "mouseup", this.onTouchEnd)
      document.addEventListener(isTouch ? "touchmove" : "mousemove", this.onTouchMove)
      this.dragging = {
        x: (isTouch ? ev.touches[0] : ev).clientX,
        y: (isTouch ? ev.touches[0] : ev).clientY,
      }
    },

    onTouchMove(ev) {
      const { isTouch } = this
      if (isTouch && !ev.touches.length) {
        return
      }

      const { clientX, clientY } = (isTouch ? ev.touches[0] : ev),
            offsetX = this.dragging.x - clientX,
            offsetY = this.dragging.y - clientY

      if (isTouch && Math.abs(offsetX) < Math.abs(offsetY)) {
        // user tries to scroll page
        return
      }

      ev.stopImmediatePropagation()
    },

    onTouchEnd(ev) {
      const { isTouch } = this
      if (isTouch && !ev.changedTouches.length) {
        return
      }

      const { clientX } = (isTouch ? ev.changedTouches[0] : ev),
            deltaX = this.dragging.x - clientX,
            minDragLength = 10 // todo: adjust

      if (Math.abs(deltaX) > minDragLength) {
        this.active += Math.sign(deltaX)
      }

      document.removeEventListener(isTouch ? "touchend" : "mouseup", this.onTouchEnd)
      document.removeEventListener(isTouch ? "touchmove" : "mousemove", this.onTouchMove)
    },

    onKeydown(ev) {
      if (!this.isFullscreen) {
        return
      }

      const action = KEYBOARD_ACTIONS[ev.code]
      if (!action) {
        return
      }

      ev.preventDefault()
      switch (action) {
      case NEXT_SLIDE:
        ++this.active
        return
      case PREV_SLIDE:
        --this.active
        return
      case EXIT_FULLSCREEN:
        this.toggleFullscreen()
        return
      }
    },

    updateThumbnails() {
      if (this.dots) {
        return
      }

      const { thumbs, thumbNav } = this.$refs,
            thumb = thumbs[this.index]
      if (!thumb) {
        return
      }

      const { left: containerLeft, width: containerWidth } = thumbNav.getBoundingClientRect(),
            { left: thumbLeft, width: thumbWidth } = thumb.getBoundingClientRect(),
            escapePadding = (thumbWidth / 3),
            thumbLeftRel = thumbLeft - containerLeft,
            thumbCenter = thumbLeft + (thumbWidth / 2),
            containerCenter = containerLeft + (containerWidth / 2),
            centerOffset = thumbCenter - containerCenter

      if (thumbLeftRel - escapePadding < 0) {
        // escaping to the left?
        this.thumbOffset = Math.min(0, this.thumbOffset - centerOffset)
      } else if (thumbLeftRel + thumbWidth + escapePadding > containerWidth) {
        // escaping to the right?
        const maxOffset = containerWidth - thumbNav.querySelector(".wrapper").scrollWidth
        this.thumbOffset = Math.max(maxOffset, this.thumbOffset - centerOffset)
      }
    },
  },
}
</script>

<style lang="scss">
@use "sass:math";

// see also app/javascript/stylesheets/application/_gallery.sass
$controls-width: 75px;

body.fullscreen-gallery {
  overflow: hidden;

  #go-top {
    display:          none !important;
  }

  .gallery {
    position:         fixed;
    top:              0;
    left:             0;
    right:            0;
    bottom:           0;
    z-index:          9999;

    background-color: #000;
    padding:          floor(0.2*$controls-width);
  }

  .carousel {
    box-shadow:       none;
  }

  .thumbnails {
    position:         absolute;
    bottom:           floor(5px + 0.2*$controls-width);
    left:             floor(5px + 0.2*$controls-width);
    right:            floor(5px + 0.2*$controls-width);
  }

  @media screen and (min-width: 1280px) {
    .gallery {
      padding:        10px;
    }
    .thumbnails {
      bottom:         5px;
      left:           10px;
      right:          10px;
    }
  }

  .controls {
    pointer-events:   all;
    align-items:      center;

    button {
      margin:         12px;
      height:         50px;
      width:          50px;
      line-height:    50px;
      border-radius:  50%;
      background:     #3338;
      transition:     background-color 300ms ease-in-out;

      &:hover {
        background:   #000e;
        text-shadow:  none;
      }
    }

    .controls-exit-fullscreen {
      display:        initial;
    }
  }
}

.gallery {
  .carousel {
    box-shadow:       0 0 15px -5px #000;
    position:         relative;
    overflow:         hidden;
    max-height:       100%;
  }

  .dots {
    display: flex;
    justify-content: center;
    flex-wrap: wrap;
    gap: 5px;
  }

  .thumbnails {
    overflow-x:       hidden;

    .wrapper {
      position:       relative;
      left:           0; // adjusted in updateThumbnails()
      transition:     left 500ms ease-in-out;

      display:        flex;
      gap:            5px;
    }

    a {
      border:         5px solid transparent;
      transition:     border-color 200ms ease-in-out
    }

    img {
      width: 80px;
      height: 80px;
    }
  }

  .controls {
    position:         absolute;
    top:              0;
    width:            100%;
    height:           100%;

    display:          flex;
    justify-content:  space-between;
    pointer-events:   none;

    button {
      pointer-events: all;
      background:     none;
      width:          $controls-width;
      border:         none;
      color:          #ccc;

      &:hover {
        color:        #fff;
        text-shadow:  0 0 5px #333;
      }
    }

    .controls-exit-fullscreen {
      display:        none;
      position:       absolute;
      top:            0;
      right:          0;
    }
  }

  .slide {
    position:         absolute;
    transform:        translateY(0); // enforce GPU rendering
    top:              0;
    width:            100%;
    height:           100%;

    text-align:       center;
    display:          flex;
    justify-content:  center;
    align-items:      center;

    outline:          none;
    img {
      object-fit:     contain;
      max-width:      100%;
      max-height:     100%;

      background:     transparent url("@/images/loader.gif") center no-repeat;
    }

    &.left-enter-active, &.left-leave-active {
      left:           0;
      transition:     left 300ms ease-in-out;
    }
    &.left-enter {
      left:           100%;
    }
    &.left-leave-to {
      left:           -100%;
    }

    &.right-enter-active, &.right-leave-active {
      right:          0;
      transition:     right 300ms ease-in-out;
    }
    &.right-enter {
      right:          100%;
    }
    &.right-leave-to {
      right:          -100%;
    }
  }
}
</style>
