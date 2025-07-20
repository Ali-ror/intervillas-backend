<template>
  <div class="w-auto">
    <a href="#" @click.prevent="openModal">
      {{ t("title") }}
    </a>

    <NewsletterSignupModal
        ref="modal"
    />
  </div>
</template>

<script>
import NewsletterSignupModal from "./NewsletterSignupModal.vue"
import { newsletterDismissed } from "./state"

import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "newsletter.signup_button" })

export default {
  components: {
    NewsletterSignupModal,
  },

  props: {
    autoShow: { type: Boolean, default: false },
  },

  data() {
    return {
      timeoutId: null,
    }
  },

  mounted() {
    if (this.autoShow && !newsletterDismissed()) {
      // wait until the user has scrolled before starting the timeout
      this._onScroll = () => {
        this.timeoutId = setTimeout(() => this.openModal(), 2000)
        window.removeEventListener("scroll", this._onScroll)
      }

      window.addEventListener("scroll", this._onScroll)
    }
  },

  beforeUnmount() {
    if (this._onScroll) {
      window.removeEventListener("scroll", this._onScroll)
    }
  },

  methods: {
    t,

    openModal() {
      if (this.timeoutId) {
        clearTimeout(this.timeoutId)
        this.timeoutId = null
      }

      this.$refs.modal.showModal()
    },
  },
}
</script>
