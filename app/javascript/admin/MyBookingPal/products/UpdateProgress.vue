<template>
  <UiCard collapsible>
    <template #heading>
      Update Progress

      <span v-if="progress.steps.length" class="ml-auto">
        {{ progress.done }} jobs done,
        {{ progress.todo }} pending
      </span>
    </template>
    <template v-if="loading" #default>
      <div class="p-3">
        <i class="fa fa-spinner fa-pulse fa-lg" />
      </div>
    </template>

    <form v-else @submit.prevent="triggerUpdate">
      <ul v-if="progress.steps" class="fa-ul">
        <li
            v-for="step of progress.steps"
            :key="step.name"
            class="my-1"
            :class="{ 'text-muted': step.completed_at === null }"
        >
          <i v-if="step.completed_at" class="fa fa-li fa-check text-success" />
          <i v-else class="fa fa-li fa-spinner fa-pulse" />
          <span class="col-wide" v-text="step.humanName" />
          <span class="col-small" v-text="step.xofy" />
          {{ step.completed_at ? 'completed' : 'started' }}
          {{ formatDateTime(step.completed_at || step.started_at) }}

          <button
              v-if="step.completed_at && progress.completed_at"
              class="mt-n1 btn btn-xxs btn-default"
              :disabled="triggering === step.name"
              @click.prevent="triggerStep(step.name)"
          >
            <i v-if="triggering === step.name" class="fa fa-spinner fa-pulse" />
            <i v-else class="fa fa-refresh" />
            Trigger update
          </button>
        </li>
      </ul>

      <button
          type="submit"
          class="btn btn-default"
          :disabled="triggering"
      >
        <i v-if="triggering === true" class="fa fa-spinner fa-pulse" />
        Perform full update
      </button>
    </form>
  </UiCard>
</template>

<script>
import UiCard from "../../../components/UiCard.vue"
import Utils from "../../../intervillas-drp/utils"
import { formatDateTime } from "../../../lib/DateFormatter"
import { UpdateProgress } from "./update_progress"

export default {
  components: {
    UiCard,
  },

  props: {
    url: { type: String, required: true },
  },

  data() {
    return {
      progress: new UpdateProgress([]),

      loading:          true,
      triggering:       false,
      refreshTimeoutId: null, // ReturnType<typeof setTimeout>
    }
  },

  async mounted() {
    await this.fetchProgress()
    this.loading = false
  },

  beforeDestroy() {
    this.stopRefresh()
  },

  methods: {
    formatDateTime,

    async fetchProgress() {
      const data = await Utils.fetchJSON(this.url)
      this.updateProgress(data)
    },

    async triggerUpdate() {
      this.triggering = true
      this.stopRefresh()

      const data = await Utils.patchJSON(this.url)
      this.updateProgress(data)
      this.triggering = false
    },

    async triggerStep(name) {
      this.triggering = name

      const data = await Utils.patchJSON(this.url, { step: name })
      this.updateProgress(data)
      this.triggering = false
    },

    updateProgress(data) {
      this.progress = new UpdateProgress(data)

      this.stopRefresh()
      if (this.progress.todo > 0) {
        this.refreshTimeoutId = setTimeout(() => this.fetchProgress(), 2000)
      }
    },

    stopRefresh() {
      if (this.refreshTimeoutId !== null) {
        clearTimeout(this.refreshTimeoutId)
        this.refreshTimeoutId = null
      }
    },
  },
}
</script>

<style lang="css" scoped>
  .col-wide {
    display: inline-block;
    width: 250px;
  }
  .col-small {
    display: inline-block;
    width: 75px;
    text-align: center;
  }
</style>
