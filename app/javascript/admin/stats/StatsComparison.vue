<template>
  <div>
    <h1>Belegungsstatistiken</h1>

    <label for="select-villa">Villa auswählen</label>
    <select
        id="select-villa"
        v-model="villaParam"
        @change="navigate()"
    >
      <option
          v-for="v in villas"
          :key="v.param"
          :value="v.param"
      >
        {{ v.name }}
      </option>
    </select>
    <br>
    <label for="select-year">Jahre vergleichen</label>
    <select
        id="select-year"
        v-model="year"
        @change="navigate()"
    >
      <option
          v-for="y in optionYears"
          :key="`option${y}`"
          :value="y"
      >
        {{ y - 1 }}-{{ y }}
      </option>
    </select>
    <RouterView
        v-if="villa"
        :villa-name="villa.name"
    />
  </div>
</template>

<script>
import Utils from "../../intervillas-drp/utils"
import VueRouter from "vue-router"
import StatsComparisonShow from "./StatsComparisonShow.vue"
import { sortBy } from "lodash"

let router = null
if (/^\/admin\/stats\/compare(?:\/(?:\d+([^/]+)?))?/.test(window.location.pathname)) {
  router = new VueRouter({
    routes: [
      { path: "/:villaParam/:year", component: StatsComparisonShow, name: "show", props: true },
    ],
  })
}

export default {
  name: "StatsComparison",
  router,

  data() {
    return {
      villas:     [],
      villaParam: this.$route.params.villaParam,
      year:       this.$route.params.year,
    }
  },

  computed: {
    villa() {
      return this.villas.find(v => v.param === this.villaParam)
    },

    optionYears() {
      const years = []
      const currentYear = (new Date()).getFullYear()
      for (let i = 2010; i <= currentYear; i++) {
        years.push(i)
      }
      return years
    },
  },

  watch: {
    $route(to, from) {
      this.villaParam = to.params.villaParam
      this.year = to.params.year
    },
  },

  beforeMount() {
    Utils.fetchJSON("/api/villas/prefetch.json").then(data => {
      this.villas = sortBy(data.map(villa => ({
        name:  villa.name,
        param: villa.path.split("/").slice(-1)[0],
      })), v => v.name)
    })
  },

  methods: {
    navigate() {
      if (this.villaParam && this.year) {
        this.$router.push({ name: "show", params: { villaParam: this.villaParam, year: this.year } })
      }
    },
  },
}
</script>
