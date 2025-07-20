<template>
  <div>
    <a
        v-if="!isReady"
        :href="directURL()"
        rel="nofollow"
        target="_blank"
        v-text="translate('footer.chat_with_us')"
    />
    <LiveChatWidget
        v-if="loadChat"
        :license="license"
        :session-variables="vars"
        @ready="isReady = true"
    />
  </div>
</template>

<script>
import { translate } from "@digineo/vue-translate"
import { LiveChatWidget } from "@livechat/widget-vue/v2"

const LIVE_CHAT_GROUP_IDS = {
  de: 1,
  en: 2,
}

export default {
  components: {
    LiveChatWidget,
  },

  props: {
    delay:    { type: Number, default: 5 },
    ivNumber: { type: String, default: null },
  },

  data() {
    return {
      license:  "13874676",
      isReady:  false,
      loadChat: false,
    }
  },

  computed: {
    vars() {
      const vars = {}
      if (this.ivNumber) {
        vars["Booking"] = this.ivNumber
      }
      return vars
    },
  },

  mounted() {
    const offset = 100

    if (window.scrollY > offset) {
      this.loadChat = true
    } else {
      const onScroll = () => {
        if (window.scrollY > offset) {
          this.loadChat = true
          window.removeEventListener("scroll", onScroll)
        }
      }

      setTimeout(() => {
        this.loadChat = true
        window.removeEventListener("scroll", onScroll)
      }, this.delay * 1000)
      window.addEventListener("scroll", onScroll)
    }
  },

  methods: {
    translate,

    directURL() {
      const { lang } = document.body,
            id = LIVE_CHAT_GROUP_IDS[lang] || ""

      return `https://direct.lc.chat/${this.license}/${id}`
    },
  },
}
</script>
