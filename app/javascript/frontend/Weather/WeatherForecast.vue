<template>
  <div class="position-relative mt-4">
    <div class="d-flex flex-column justify-content-around flex-md-row align-items-center">
      <div class="d-flex align-items-center gap-2" :title="current.desc">
        <strong>Cape Coral</strong>
        <img
            :src="current.icon"
            :alt="current.desc"
            width="128"
        >
        <span>
          <strong>
            {{ current.high }}{{ metric ? "℃" : "℉" }}
          </strong> / <a
              href="#"
              @click.prevent="metric = !metric"
              v-text="metric ? '℉' : '℃'"
          />
        </span>
      </div>

      <div class="d-flex justify-self-stretch gap-4">
        <WeatherItem
            v-for="f, i in forecast"
            :key="i"
            v-bind="f"
            :metric="metric"
        />
      </div>
    </div>
    <a
        href="https://openweathermap.org/city/4149962"
        class="attribution"
        rel="noopener noreferrer"
        target="_blank"
    >
      <i class="fa fa-info" />
      <small>
        <img :src="owLogo" height="20">
        Weather data provided by OpenWeather
      </small>
    </a>
  </div>
</template>

<script>
import icon01d from "@/images/weather/01d.svg"
import icon01n from "@/images/weather/01n.svg"
import icon02d from "@/images/weather/02d.svg"
import icon02n from "@/images/weather/02n.svg"
import icon03d from "@/images/weather/03d.svg"
import icon03n from "@/images/weather/03n.svg"
import icon04d from "@/images/weather/04d.svg"
import icon04n from "@/images/weather/04n.svg"
import icon09d from "@/images/weather/09d.svg"
import icon09n from "@/images/weather/09n.svg"
import icon10d from "@/images/weather/10d.svg"
import icon10n from "@/images/weather/10n.svg"
import icon11d from "@/images/weather/11d.svg"
import icon11n from "@/images/weather/11n.svg"
import icon13d from "@/images/weather/13d.svg"
import icon13n from "@/images/weather/13n.svg"
import icon50d from "@/images/weather/50d.svg"
import icon50n from "@/images/weather/50n.svg"
import WeatherItem from "./WeatherItem.vue"
import OpenWeatherLogo from "@/images/weather/OpenWeather.svg"

const icons = {
  "01d": icon01d,
  "01n": icon01n,
  "02d": icon02d,
  "02n": icon02n,
  "03d": icon03d,
  "03n": icon03n,
  "04d": icon04d,
  "04n": icon04n,
  "09d": icon09d,
  "09n": icon09n,
  "10d": icon10d,
  "10n": icon10n,
  "11d": icon11d,
  "11n": icon11n,
  "13d": icon13d,
  "13n": icon13n,
  "50d": icon50d,
  "50n": icon50n,
}

export default {
  components: {
    WeatherItem,
  },

  props: {
    weather: { type: Array, required: true },
  },

  data() {
    return {
      locale: document.body.lang,
      metric: true,
      owLogo: OpenWeatherLogo,
    }
  },

  computed: {
    current() {
      return this.localize(this.weather[0])
    },
    forecast() {
      return this.weather.slice(2).map(w => this.localize(w))
    },
  },

  methods: {
    localize({ timestamp, condition, high, low }) {
      const { cat, desc } = condition[this.locale === "de" ? "de" : "en"]

      return {
        t:    new Date(timestamp),
        icon: icons[condition.icon],
        cat,
        desc,
        high: high[this.metric ? 0 : 1],
        low:  low[this.metric ? 0 : 1],
      }
    },
  },
}
</script>

<style lang="scss">
  a.attribution {
    color: #aaa;
    padding: 4px;

    position: absolute;
    top: 0;
    right: 0;

    & small {
      display: none;
    }

    &:hover {
      & > small {
        display: block
      }
      & > i.fa {
        display: none
      }
    }
  }
</style>
