<template>
  <VModal
      name="newsletter"
      :max-width="600"
      height="auto"
      adaptive
      @before-close="onCloseModal"
  >
    <div class="px-3 py-2">
      <div class="d-flex justify-content-between align-items-center">
        <h2 v-text="t('title')" />
        <a
            href="#"
            class="close"
            @click.prevent="hideModal(false)"
        >
          <i class="fa fa-fw fa-lg fa-times" />
        </a>
      </div>

      <NewsletterSignupForm
          @done="hideModal(true)"
      />
    </div>
  </VModal>
</template>

<script>
import NewsletterSignupForm from "./NewsletterSignupForm.vue"
import { dismissNewsletter } from "./state"

import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "newsletter.signup_modal" })

export default {
  components: {
    NewsletterSignupForm,
  },

  methods: {
    t,

    showModal() {
      document.querySelector("body").style.overflow = "hidden"
      this.$modal.show("newsletter")
    },

    hideModal(dismissed) {
      dismissNewsletter(dismissed)
      this.$modal.hide("newsletter")
    },

    onCloseModal() {
      document.querySelector("body").style.overflow = ""
    },
  },
}
</script>
