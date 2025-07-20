<template>
  <div class="progress mb-0">
    <div
        v-for="step in progress.steps"
        :key="step.name"
        class="progress-bar"
        :class="{ 'progress-bar-striped': step.done !== step.todo }"
        :style="{ width: width(step) }"
        :title="`${step.humanName}, ${step.xofy}`"
    />
  </div>
</template>

<script>
import { UpdateProgress } from "./update_progress"

export default {
  props: {
    value: { type: Array, required: true },
  },

  computed: {
    progress() {
      return new UpdateProgress(this.value)
    },

    totalSteps() {
      return this.progress.steps.reduce((total, { todo }) => total + todo, 0)
    },
  },

  methods: {
    width({ name, done }) {
      if (done === 0) {
        return "5px"
      }

      const r = (done / this.totalSteps) * 100
      if (name === "start") {
        return `${r}%`
      }
      return `calc(${r}% - 1px)`
    },
  },
}
</script>

<style lang="scss" scoped>
  .progress {
    max-width: 225px;
    height: 10px;

    .progress-bar + .progress-bar {
      margin-left: 1px;
    }
  }
</style>
