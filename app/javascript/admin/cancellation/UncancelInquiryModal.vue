<template>
  <div>
    <VModal
        name="uncancellation"
        class="bg-light"
        classes="rounded-0"
        height="auto"
        :click-to-close="canClose"
        @closed="onModalHide"
    >
      <form
          action="#"
          class="panel mb-0 rounded-0"
          :class="location ? 'pandel-success' : 'panel-default'"
          @submit.prevent="submit"
      >
        <div class="panel-heading rounded-0">
          <button
              v-if="canClose"
              class="close"
              type="button"
              @click.prevent="hideModal()"
          >
            <i v-if="saving" class="fa fa-spinner fa-pulse" />
            <i v-else class="fa fa-times" />
          </button>

          {{ t("heading") }}
        </div>

        <template v-if="location">
          <div class="panel-body">
            <p class="d-flex align-items-center py-3">
              <i class="fa fa-check text-success fa-2x mr-3" />
              {{ t("success", { number: `IV-${id}` }) }}
            </p>
          </div>

          <div class="panel-footer text-right rounded-0">
            <p>
              <a
                  class="btn btn-default btn-sm"
                  :href="indexUrl"
                  v-text="t('goto.index')"
              />
              <a
                  class="btn btn-primary btn-sm"
                  :href="location"
                  v-text="t('goto.booking')"
              />
            </p>
          </div>
        </template>

        <template v-else>
          <div class="panel-body">
            <p v-text="t('description')" />

            <p v-if="error" class="text-danger">
              {{ t("error") }} ({{ error }})
            </p>
          </div>

          <div class="panel-footer text-right rounded-0">
            <button
                type="button"
                :disabled="!canClose"
                class="btn btn-sm btn-default"
                @click.prevent="hideModal()"
                v-text="translate('generic.cancel')"
            />
            <button
                type="submit"
                :disabled="!canClose"
                class="btn btn-sm btn-warning"
                v-text="t('create')"
            />
          </div>
        </template>
      </form>
    </VModal>

    <button class="btn btn-warning btn-sm" @click.prevent="showModal">
      <span v-text="t('create')" />
    </button>
  </div>
</template>

<script>
import Utils from "../../intervillas-drp/utils"
import { translate } from "@digineo/vue-translate"

const t = (key, opts = {}) => translate(key, { ...opts, scope: "inquiry_editor.uncancellation" })

export default {
  props: {
    indexUrl: { type: String, required: true }, // bookings or inquiries index
    url:      { type: String, required: true }, // POST endpoint
    id:       { type: Number, required: true }, // inquiry id
  },

  data() {
    return {
      saving:   false,
      error:    null, // submit failure
      location: null, // cancellation sucessful -> target url
    }
  },

  computed: {
    canClose() {
      return this.saving || !this.location
    },
  },

  methods: {
    translate,
    t,

    showModal() {
      // reset
      this.error = null
      this.location = null

      this.$nextTick(() => {
        document.querySelector("body").style.overflow = "hidden"
        this.$modal.show("uncancellation")
      })
    },

    hideModal() {
      if (this.saving) {
        return // don't close until saved
      }

      this.$modal.hide("uncancellation")
    },

    onModalHide() {
      document.querySelector("body").style.overflow = ""
    },

    async submit() {
      if (this.saving) {
        return
      }

      this.saving = true
      this.error = null

      try {
        const { error, location } = await Utils.deleteJSON(this.url)
        if (error) {
          this.error = error
        } else {
          this.location = location
        }
      } catch (err) {
        this.error = err?.error || t("unknown_error")
      } finally {
        this.saving = false
      }
    },
  },
}
</script>

<style lang="scss">
  .v--modal-overlay[data-modal="uncancellation"] {
    .v--modal {
      background-color: #fff;
    }

    textarea {
      resize: vertical;
    }
  }
</style>
