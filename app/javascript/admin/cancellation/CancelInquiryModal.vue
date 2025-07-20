<template>
  <div>
    <VModal
        name="cancellation"
        class="bg-light"
        classes="rounded-0"
        height="auto"
        :click-to-close="canClose"
        @opened="focusReason"
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
                  v-text="t('goto.cancellation')"
              />
            </p>
          </div>
        </template>

        <template v-else>
          <div class="panel-body">
            <div
                class="form-group"
                :class="{ 'has-error': $v.reason.$error }"
            >
              <label for="reason" class="control-label">{{ t("reason") }}</label>
              <textarea
                  id="reason"
                  ref="reason"
                  v-model.trim="reason"
                  name="reason"
                  :required="$v.reason.$params.required"
                  :disabled="saving"
                  class="form-control"
                  rows="5"
              />
              <span class="help-block" v-text="t('reason_hint')" />
            </div>

            <p v-if="error" class="text-danger">
              {{ t('error') }}: {{ error }}
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
                class="btn btn-sm btn-danger"
                v-text="t('create')"
            />
          </div>
        </template>
      </form>
    </VModal>

    <button class="btn btn-default text-danger btn-sm" @click.prevent="showModal">
      <span class="text-danger" v-text="t('create')" />
    </button>
  </div>
</template>

<script>
import { validationMixin } from "vuelidate"
import { required } from "vuelidate/lib/validators"
import Utils from "../../intervillas-drp/utils"
import { translate } from "@digineo/vue-translate"
const t = (key, opts = {}) => translate(key, { ...opts, scope: "inquiry_editor.cancellation" })

export default {
  mixins: [validationMixin],

  props: {
    indexUrl: { type: String, required: true }, // bookings or inquiries index
    url:      { type: String, required: true }, // POST endpoint
    id:       { type: Number, required: true }, // inquiry id
  },

  data() {
    return {
      saving:   false,
      reason:   null, // payload for Cancellation#reason
      error:    null, // submit failure
      location: null, // cancellation sucessful -> target url
    }
  },

  validations() {
    return {
      reason: { required },
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
      this.reason = null
      this.error = null
      this.location = null
      this.$v.$reset()

      this.$nextTick(() => {
        document.querySelector("body").style.overflow = "hidden"
        this.$modal.show("cancellation")
      })
    },

    hideModal() {
      if (this.saving) {
        return // don't close until saved
      }

      this.$modal.hide("cancellation")
    },

    focusReason() {
      this.$nextTick(() => {
        if (this.$refs.reason) {
          this.$refs.reason.focus()
        }
      })
    },

    onModalHide() {
      document.querySelector("body").style.overflow = ""
    },

    async submit() {
      if (this.saving || this.$v.$error) {
        return
      }

      this.saving = true
      this.error = null

      const { id, reason } = this,
            payload = { cancellation: { id, reason } }

      try {
        const { error, location } = await Utils.postJSON(this.url, payload)
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
  .v--modal-overlay[data-modal="cancellation"] {
    .v--modal {
      background-color: #fff;
    }

    textarea {
      resize: vertical;
    }
  }
</style>
