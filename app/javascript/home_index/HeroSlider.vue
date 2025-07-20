<template>
  <section class="banner-slider" :style="{ backgroundColor: themeColor }">
    <Transition name="slide">
      <picture :key="current.src" class="banner-slide">
        <img :src="current.src">
        <source :srcset="current.srcset">
      </picture>
    </Transition>

    <div class="banner-slide">
      <div class="inner">
        <Transition name="disrupt">
          <a
              v-if="urls.boats && isDisruption"
              :href="urls.boats"
              class="disruption"
          >
            <img :src="boatRentalSVG">

            <strong class="banner-big-text">
              {{ "home.dynamic.slide.disrupt.boat_rental" | translate }}
            </strong>
            <span class="btn btn-slider btn-lg">
              {{ "home.dynamic.slide.disrupt.goto_boat_rental" | translate }}
              <i class="fa fa-arrow-right" />
            </span>
          </a>

          <div v-else class="florida-is-waiting">
            <strong class="banner-big-text">
              Florida is waiting for you
            </strong>
            <a class="btn btn-slider btn-lg" :href="urls.villas">
              {{ "home.dynamic.slide.view" | translate }}
            </a>
          </div>
        </Transition>
      </div>
    </div>
  </section>
</template>

<script>
import boatRentalSVG from "./boat-rental.svg"

function partitionSlides(slideSet) {
  const src = slideSet[0].src
  const srcset = slideSet.reduce((s, { width, src }, i) => {
    if (i === 0) {
      s.push(`${src}`)
    } else {
      s.push(`${src} ${width}w`)
    }
    return s
  }, []).join(", ")

  return { src, srcset }
}

const DISRUPTOR_DISPLAY_TIME = 3000, // how long to show the disruptor state (in millis)
      NORMAL_DISPLAY_TIME = 13000, // how long to show the non-disruptor state (in millis)
      TRANSITION_DURATION = 800 // animation-duration of .disrupt-enter-active (in millis)

export default {
  name: "HeroSlider",

  data() {
    return {
      list:  [],
      index: 0, // index into list (mod list.length)

      // interval duration, must be > disruptorInterval + animation-duration of disrupt-enter-active
      playerInterval: NORMAL_DISPLAY_TIME + DISRUPTOR_DISPLAY_TIME + (TRANSITION_DURATION / 2),
      player:         null, // interval ID

      themeColor: null, // theme color of site (<meta name="theme-color" />)

      urls: {
        villas:        null, // link home.dynamic.slide.view points to
        boats:         null, // link boat disruptor points to
        searchProfile: null, // link search profile disruptor points to (TODO)
      },

      // how long to wait before transitioning to disruptor view?
      // will be reset when the slide changes (via index watcher)
      disruptorTimeout: NORMAL_DISPLAY_TIME,
      disruptor:        null, // timeout ID
      isDisruption:     false, // toggles default and disruptor view
      boatRentalSVG,
    }
  },

  computed: {
    current() {
      return this.list[this.index % this.list.length]
    },
  },

  watch: {
    index() {
      this.isDisruption = false
      this.startDisruptor()
    },
  },

  beforeMount() {
    const ds = this.$el.dataset

    this.list = JSON.parse(ds.slides).map(slide => partitionSlides(slide))

    const { villas, boats, searchProfile } = ds
    this.urls = { villas, boats, searchProfile }

    const theme = document.querySelector('head meta[name="theme-color"]')
    if (theme) {
      this.themeColor = theme.getAttribute("content")
    }
  },

  mounted() {
    this.startPlayer()
    this.startDisruptor()
  },

  beforeDestroy() {
    this.stopAll()
  },

  methods: {
    startPlayer() {
      this.player = setInterval(() => ++this.index, this.playerInterval)
    },

    startDisruptor() {
      if (this.disruptor) {
        clearTimeout(this.disruptor)
      }
      if (this.urls.boats || this.urls.searchProfile) {
        this.disruptor = setTimeout(() => this.isDisruption = true, this.disruptorTimeout)
      }
    },

    stopAll() {
      if (this.player) {
        clearInterval(this.player)
        this.player = null
      }
      if (this.disruptor) {
        clearTimeout(this.disruptor)
        this.disruptor = null
      }
    },
  },
}
</script>

<style lang="scss">
.banner-slider {
  height: 100vh;
  width: 100vw;
  position: relative;

  .banner-nav, .banner-slide {
    position: absolute;
    height: 100%;
  }

  picture.banner-slide img {
    object-fit: cover;
    width: 100%;
    height: 100%;
  }

  .banner-slide {
    width: 100%;
    top: 0;
    left: 0;
    text-align: center;

    .banner-big-text {
      display: block;
      color: #fff;
      text-shadow: 0 3px 15px #333;
      font-size: 45px;
      line-height: 1.3;
      text-transform: uppercase;
      padding: 6px 50px;

      @media screen and (max-width: 767px) {
        font-size: 32px;
      }
    }

    &.slide-enter-active, &.slide-leave-active {
      transition: left 1s ease-in-out
    }
    &.slide-enter {
      left: 100%;
    }
    &.slide-leave-to {
      left: -100%;
    }

    .inner {
      width: 100%;
      height: 100%;
      position: relative;
      overflow: hidden;

      img {
        filter: drop-shadow(0 0 5px #000);
        object-fit: contain;
        height: 300px;
        max-height: 40vh;
        max-width: 80%;
      }

      > * {
        display: block;
        width: 100%;
        position: absolute;
        top: 50%;
        transform: translateY(-50%);
      }

      .disrupt-enter-active,
      .disrupt-leave-active {
        animation-duration: 0.8s;
        animation-fill-mode: both;
        animation-name: disrupt;
        animation-timing-function: ease-out;
      }

      .disrupt-leave-active {
        animation-direction: reverse;
        animation-timing-function: ease-in;
      }
    }
  }
}

@keyframes disrupt {
  from {
    opacity: 0;
    transform: translateY(-33%);
  }
  to {
    opacity: 1;
    transform: translateY(-50%);
  }
}
</style>
