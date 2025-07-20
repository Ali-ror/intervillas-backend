<template>
  <div class="forecast" :title="desc">
    <small class="date text-muted" v-text="dow" />
    <div class="icon">
      <img :src="icon" :alt="desc">
    </div>
    <div class="temp text-nowrap">
      {{ high }}{{ deg }}<br>
      <span class="text-muted">{{ low }}{{ deg }}</span>
    </div>
  </div>
</template>

<script>
import { format } from "date-fns"
export default {
  props: {
    t:      { type: Date, required: true },
    icon:   { type: String, required: true },
    cat:    { type: String, default: null },
    desc:   { type: String, required: true },
    high:   { type: Number, required: true },
    low:    { type: Number, required: true },
    metric: { type: Boolean, required: true },
  },

  computed: {
    dow() {
      const fmt = document.body.lang === "de" ? "iiiiii." : "iii"
      return format(this.t, fmt)
    },
    deg() {
      return this.metric ? "℃" : "℉"
    },
  },
}
</script>

<style lang="scss">
  .forecast {
    display: grid;
    grid-template-areas: "date" "icon" "temp";

    justify-content: center;
    align-items: center;

    .date {
      grid-area: date;
      text-align: center;
      text-transform: uppercase;
    }
    .icon {
      grid-area: icon;
      text-align: center;
      img {
        height: 48px
      }
    }
    .temp {
      grid-area: temp;
      text-align: center;
    }

    @media screen and (min-width: 1200px) {
      grid-template-areas:
        "date date"
        "icon temp";
      grid-template-columns: 1fr 1fr;
      grid-template-rows:    1.2em 64px;

      .icon {
        justify-self: end;
      }
    }
  }
</style>
