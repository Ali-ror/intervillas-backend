<template>
  <div v-outside-click="closeDropdowns">
    <button
        class="btn btn-default"
        type="button"
        @click="goto(-1)"
    >
      <i class="fa fa-chevron-left" />
    </button>

    <div class="btn-group">
      <div
          v-for="y in [year -1, year, year+1]"
          :key="y"
          class="btn-group"
          :class="{ open: opened === y }"
      >
        <button
            class="btn dropdown-toggle"
            :class="y === currentYear ? 'btn-primary' : 'btn-default'"
            type="button"
            @click="opened = y"
        >
          {{ y }}
          <i class="fa fa-caret-down" />
        </button>
        <ul class="dropdown-menu">
          <li
              v-for="(human, m) in months"
              :key="m"
              :class="{ active: y === currentYear && m === currentMonth }"
          >
            <a
                :href="adminGridPath(y, m)"
                v-text="human"
            />
          </li>
        </ul>
      </div>
    </div>

    <button
        class="btn btn-default"
        type="button"
        @click="goto(1)"
    >
      <i class="fa fa-chevron-right" />
    </button>
  </div>
</template>

<script>
import { translate } from "@digineo/vue-translate"

export default {
  props: {
    urlTemplate: { type: String, required: true },
  },

  data() {
    const now = new Date(),
          y = now.getUTCFullYear(),
          m = now.getUTCMonth()
    return {
      currentYear:  y,
      currentMonth: m,

      minYear: 2010,
      maxYear: y + 5,
      year:    y,
      months:  translate("date.month_names").slice(1),
      opened:  null,
    }
  },

  computed: {
  },

  methods: {
    adminGridPath(year, month) {
      return this.urlTemplate
        .replace(/\/9009/, `/${year}`)
        .replace(/\/99/, `/${month + 1}`)
    },

    closeDropdowns() {
      this.opened = false
    },

    goto(dir) {
      this.opened = false
      this.year += dir
      if (this.year < this.minYear + 1) {
        this.year = this.minYear + 1
      } else if (this.year > this.maxYear - 1) {
        this.year = this.maxYear - 1
      }
    },
  },
}
</script>
