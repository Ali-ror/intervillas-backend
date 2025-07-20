<template>
  <UiCard collapsible>
    <template #heading>
      Image Imports

      <span v-if="images.length" class="ml-auto">
        {{ summary.success }} imported,
        {{ summary.pending }} pending,
        {{ summary.failure }} failed
      </span>
    </template>

    <AsyncLoader :url="url" @data="images = $event">
      <div class="media-list">
        <div
            v-for="i in images"
            :key="i.id"
            class="img-thumbnail media-list-item p-0"
            :class="{ inactive: i.status !== 'success' }"
            :title="i.version ? `Version: ${i.version}` : undefined"
        >
          <div class="list-thumb mb-1">
            <img :src="i.thumbnail">
          </div>
          <div v-if="i.status === 'pending'" class="handle small text-center text-muted">
            <i class="fa fa-hourglass-half" />
            pending import
          </div>
          <div v-else-if="i.status === 'success'" class="handle small text-center text-success">
            <i class="fa fa-check" />
            imported
          </div>
          <div v-else-if="i.status === 'failure'" class="handle small text-center text-danger">
            <i class="fa fa-times" />
            import failure
          </div>
          <div v-else-if="i.status === 'deleted'" class="handle small text-center text-muted">
            <i class="fa fa-times" />
            <s>removed</s>
          </div>
        </div>
      </div>
    </AsyncLoader>

    <div class="d-flex justify-content-start align-items-baseline gap-2 mt-3">
      <button
          class="btn btn-default"
          :disabled="syncing"
          @click.prevent="forceSync"
      >
        <i v-if="syncing" class="fa fa-spinner fa-pulse" />
        Sync manually
      </button>

      <p class="text-muted">
        When synchronizing the image list manually, we'll fetch the list of images
        currently known to MyBookingPal and update the status.
      </p>
    </div>
  </UiCard>
</template>

<script>
import UiCard from "../../../components/UiCard.vue"
import Utils from "../../../intervillas-drp/utils"
import AsyncLoader from "../../AsyncLoader.vue"

export default {
  components: {
    UiCard,
    AsyncLoader,
  },

  props: {
    url: { type: String, required: true },
  },

  data() {
    return {
      images:           [],
      syncing:          false,
      refreshTimeoutId: null, // ReturnType<typeof setTimeout>
    }
  },

  computed: {
    summary() {
      return this.images.reduce((s, img) => (++s[img.status], s), {
        pending: 0,
        success: 0,
        failure: 0,
        deleted: 0,
      })
    },
  },

  beforeDestroy() {
    this.stopRefresh()
  },

  methods: {
    async fetchImages() {
      const data = await Utils.fetchJSON(this.url)
      this.images = data

      this.stopRefresh()
      if (this.images.some(i => i.status === "pending")) {
        this.refreshTimeoutId = setTimeout(() => this.fetchImages(), 10000)
      }
    },

    async forceSync() {
      this.stopRefresh()
      this.syncing = true
      const data = await Utils.postJSON(this.url)
      this.images = data
      this.syncing = false
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

<style scoped>
.media-list .media-list-item {
  cursor: inherit;
}
</style>
