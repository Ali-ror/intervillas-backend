<template>
  <div>
    <slot v-if="loading" name="loader">
      <div class="well text-center py-5">
        <i class="fa fa-spinner fa-pulse fa-3x text-muted" />
      </div>
    </slot>

    <slot
        v-else-if="loadError"
        name="load-error"
        :error="loadError"
    >
      <div class="alert alert-danger">
        Failed to load data.
        ({{ loadError.message }})
      </div>
    </slot>

    <slot v-else />
  </div>
</template>

<script>
import { isAxiosError } from "axios"
import Utils from "../intervillas-drp/utils"
export default {
  props: {
    url: { type: String, required: true },
  },

  data() {
    return {
      loading:   new AbortController(),
      loadError: null,
    }
  },

  watch: {
    url() {
      this.fetchData()
    },
  },

  mounted() {
    this.fetchData()
  },

  methods: {
    async fetchData() {
      if (this.loading) {
        this.loading.abort()
      }

      this.loading = new AbortController()
      this.loadError = null
      const { signal } = this.loading

      try {
        const data = await Utils.fetchJSON(this.url, signal)
        this.$emit("data", data)
        this.loading = null
      } catch (err) {
        if (isAxiosError(err)) {
          if (err.config?.signal?.aborted) {
            return // superseeded by different request
          }
          if (err.response?.status === 404) {
            this.$emit("data", null)
          } else {
            this.loadError = err
          }

          this.loading = null
        }
      }
    },
  },
}
</script>
