<template>
  <div
      class="markdown-editor"
      :style="{ height: `${verticalSpace}px` }"
  >
    <div
        class="row controls"
        :style="{ height: `${toolbarHeight}px` }"
    >
      <div class="col-sm-6">
        <h4
            v-if="title"
            v-text="title"
        />
      </div>

      <div class="col-sm-6">
        <a
            class="pull-right text-muted"
            href="#"
            @click.prevent="$emit('close')"
        >
          Editor schließen <i class="fa fa-compress fa-2x" />
        </a>
        <h4>Vorschau</h4>
      </div>
    </div>
    <div class="row">
      <div class="col-sm-6">
        <textarea
            ref="input"
            v-model.trim="markdown"
            class="no-resize form-control"
            :style="{ height: `${height}px` }"
            @change="renderPreview"
            @keyup="renderPreview"
            @paste="renderPreview"
        />
      </div>
      <div class="col-sm-6">
        <div
            class="preview"
            :style="{ height: `${height}px` }"
        >
          <!-- eslint-disable vue/no-v-html -->
          <div
              class="form-control"
              v-html="rendered"
          />
          <!-- eslint-enable vue/no-v-html -->
          <span
              v-if="loading"
              class="loader label label-info"
          >
            <i class="fa fa-spinner fa-spin" />
            Lade Vorschau&hellip;
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { debounce } from "lodash"
import Utils from "../intervillas-drp/utils"

const HEADER_HEIGHT = 90, // approx height of `header .navbar.shrink`
      HEADER_PADDING = 10, // some padding
      TOOLBAR_HEIGHT = 35 // height of a button

const PREVIEW_ENDPOINT = "/api/admin/markdown/preview"

const IGNORED_KEY_CODES = [
  37, // ArrowLeft
  38, // ArrowUp
  39, // ArrowRight
  40, // ArrowDown
]

export default {
  props: {
    title: { type: String, default: "" },
    value: { type: String, required: true },
  },

  data() {
    return {
      verticalSpace: Math.floor(window.innerHeight - HEADER_HEIGHT - HEADER_PADDING),
      rendered:      "",
      loading:       false,
      lastValue:     "",

      scrollToOnClose:      0,
      hideIndicatorTimeout: null,
    }
  },

  computed: {
    height() {
      return Math.floor(this.verticalSpace - TOOLBAR_HEIGHT - 10)
    },

    toolbarHeight() {
      return TOOLBAR_HEIGHT
    },

    markdown: {
      get() {
        return this.value
      },
      set(md) {
        this.$emit("input", md)
      },
    },
  },

  beforeMount() {
    this.scrollToOnClose = window.scrollY
  },

  mounted() {
    const r = this.$el.getClientRects()[0]
    this.verticalSpace = Math.floor(window.innerHeight - HEADER_HEIGHT - HEADER_PADDING)
    this.renderPreview()
    this.$nextTick(() => {
      window.scrollTo(0, Math.floor(r.top - HEADER_HEIGHT - HEADER_PADDING))
      this.$refs.input.focus()
      this.$refs.input.selectionStart = 0
      this.$refs.input.selectionEnd = 0
      this.$refs.input.scrollTop = 0
    })

    // we want to close this, even if the component does not have focus
    document.addEventListener("keydown", this.onEscape.bind(this))
  },

  beforeDestroy() {
    document.removeEventListener("keydown", this.onEscape.bind(this))
  },

  destroyed() {
    this.$nextTick(() => {
      window.scrollTo(0, this.scrollToOnClose)
    })
  },

  methods: {
    renderPreview(ev) {
      if (ev && ev.keyCode && IGNORED_KEY_CODES.includes(ev.keyCode)) {
        return
      }

      this.fetchPreview()
    },

    fetchPreview: debounce(function() {
      const content = this.value ? this.value.trim() : ""
      if (content === this.lastValue) {
        // no change
        return
      }
      if (content === "") {
        // nothing to render
        this.lastValue = this.rendered = ""
        return
      }

      this.loading = true
      this.resetIndicator()

      Utils.postJSON(PREVIEW_ENDPOINT, { content }).then(res => {
        res && res.body && (this.rendered = res.body)
        this.lastValue = this.value
        this.hideIndicator()
      })
    }, 300),

    resetIndicator() {
      if (this.hideIndicatorTimeout) {
        clearTimeout(this.hideIndicatorTimeout)
        this.hideIndicatorTimeout = null
      }
    },

    hideIndicator() {
      this.resetIndicator()
      this.hideIndicatorTimeout = setTimeout(() => {
        this.loading = false
        this.hideIndicatorTimeout = null
      }, 300)
    },

    onEscape(ev) {
      if (ev.keyCode !== 0x1b) {
        return
      }

      this.$emit("close")
    },
  },
}
</script>

<style scoped>
.controls .pull-right .fa {
  vertical-align: middle;
}

.preview {
  position: relative;
}

.preview .loader {
  position: absolute;
  top: 1em;
  left: 50%;
  transform: translateX(-50%);
  font-size: inherit;
}

.preview .form-control {
  overflow: scroll;
  position: absolute;
  height: 100%;
  width: 100%;
}

.preview .form-control *:first-child {
  margin-top: 0
}

textarea.no-resize {
  resize: none;
}
</style>
