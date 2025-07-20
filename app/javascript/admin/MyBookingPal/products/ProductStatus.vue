<template>
  <UiCard heading="Status">
    <template v-if="loading" #default>
      <div class="p-3">
        <i class="fa fa-spinner fa-pulse fa-lg" />
      </div>
    </template>

    <template v-else #default>
      <ul class="fa-ul">
        <li :class="resolved.variant">
          <i class="fa fa-li" :class="resolved.icon" />
          {{ resolved.label }}
        </li>
        <li v-if="message" :class="resolved.variant">
          {{ message }}
        </li>
      </ul>

      <form @submit.prevent>
        <button
            v-if="status === 'inactive' || status === 'validation_error'"
            class="btn btn-primary"
            :disabled="triggering"
            @click.prevent="trigger('validate')"
        >
          <i v-if="triggering" class="fa fa-spinner fa-pulse" />
          Trigger Validation
        </button>

        <button
            v-if="status === 'valid' || status === 'activation_error'"
            class="btn btn-primary"
            :disabled="triggering"
            @click.prevent="trigger('activate')"
        >
          <i v-if="triggering === 'activate'" class="fa fa-spinner fa-pulse" />
          Activate Product
        </button>

        <button
            v-if="status === 'active' || status === 'activation_error'"
            class="btn btn-warning"
            :disabled="triggering"
            @click.prevent="trigger('deactivate')"
        >
          <i v-if="triggering === 'deactivate'" class="fa fa-spinner fa-pulse" />
          Deactivate Product
        </button>
      </form>
    </template>
  </UiCard>
</template>

<script>
import UiCard from "../../../components/UiCard.vue"
import Utils from "../../../intervillas-drp/utils"

const STATES = new Map([
  ["inactive", {
    label:   "inactive",
    variant: "text-muted",
    icon:    "fa-circle-thin",
    pending: false,
  }],
  ["queued_validation", {
    label:   "queued for validation",
    variant: "text-muted",
    icon:    "fa-hourglass-half",
    pending: true,
  }],
  ["waiting_validation", {
    label:   "validation queued, waiting for result",
    variant: "text-muted",
    icon:    "fa-hourglass-half",
    pending: true,
  }],
  ["validation_error", {
    label:   "validation failed",
    variant: "text-danger",
    icon:    "fa-times",
    pending: false,
  }],
  ["valid", {
    label:   "valid",
    variant: "text-success",
    icon:    "fa-check",
    pending: false,
  }],
  ["queued_activation", {
    label:   "activation queued",
    variant: "text-muted",
    icon:    "fa-hourglass-half",
    pending: true,
  }],
  ["queued_deactivation", {
    label:   "deactivation queued",
    variant: "text-muted",
    icon:    "fa-hourglass-half",
    pending: true,
  }],
  ["activation_error", {
    label:   "activation error",
    variant: "text-danger",
    icon:    "fa-times",
    pending: false,
  }],
  ["active", {
    label:   "active",
    variant: "text-success",
    icon:    "fa-check",
    pending: false,
  }],
])

export default {
  components: {
    UiCard,
  },

  props: {
    url: { type: String, required: true },
  },

  data() {
    return {
      status:  null,
      message: null,

      loading:          true,
      triggering:       false,
      refreshTimeoutId: null, // ReturnType<typeof setTimeout>
    }
  },

  computed: {
    resolved() {
      return STATES.get(this.status) ?? {
        label:   `unknown ("${this.status}")`,
        icon:    "fa-question-circle",
        variant: "text-warning",
        pending: false,
      }
    },
  },

  async mounted() {
    await this.fetchStatus()
    this.loading = false
  },

  beforeDestroy() {
    this.stopRefresh()
  },

  methods: {
    async fetchStatus() {
      const data = await Utils.fetchJSON(this.url)
      this.updateStatus(data)
    },

    async trigger(value) {
      this.triggering = value
      this.stopRefresh()

      const data = await Utils.patchJSON(this.url, { value })
      this.updateStatus(data)
      this.triggering = false
    },

    updateStatus({ status, message }) {
      this.status = status
      this.message = message

      this.stopRefresh()
      if (this.resolved.pending) {
        this.refreshTimeoutId = setTimeout(() => this.fetchStatus(), 10000)
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
