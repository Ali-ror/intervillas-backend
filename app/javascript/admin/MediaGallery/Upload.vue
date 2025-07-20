<template>
  <div>
    <h2>Hochladen</h2>
    <div v-if="progress" class="progress">
      <div class="progress-bar" :style="`width: ${+progress}%;`">
        <i v-if="progress === 100" class="fa fa-check" />
      </div>
    </div>
    <div ref="dropzone" />
  </div>
</template>

<script>
import Uppy from "@uppy/core"
import DragDrop from "@uppy/drag-drop"
import XHRUpload from "@uppy/xhr-upload"
import German from "@uppy/locales/lib/de_DE"
import ThumbnailGenerator from "@uppy/thumbnail-generator"
import { thumbnailWidth } from "./config"

const csrfToken = () => {
  const meta = document.querySelector("meta[name=csrf-token]")
  if (meta) {
    return meta.content
  }
}

export default {
  props: {
    uploadUrl:     { type: String, required: true },
    acceptedFiles: {
      type:    Array,
      default: () => ([".jpeg", ".jpg", ".png"]),
    },
  },

  data() {
    return {
      progress: null,
    }
  },

  mounted() {
    const uppy = new Uppy({
      autoProceed:  true,
      locale:       German,
      restrictions: {
        maxFileSize:      100 * 1024 * 1024, // 100 MB
        allowedFileTypes: this.acceptedFiles,
      },
    })

    uppy.use(DragDrop, {
      target: this.$refs.dropzone,
      note:   `Erlaubte Dateien: ${this.acceptedFiles.join(", ")}, bis 100 MB`,
    })

    uppy.use(XHRUpload, {
      endpoint:  this.uploadUrl,
      limit:     1, // parallel uploads
      fieldName: "blob",
      headers:   { "X-CSRF-Token": csrfToken() },
    })
    uppy.use(ThumbnailGenerator, {
      thumbnailWidth,
    })

    uppy.on("file-added", file => {
      this.$emit("start", {
        type:          "upload",
        id:            file.id,
        filename:      file.name,
        bytesTotal:    file.progress.bytesTotal,
        bytesUploaded: file.progress.bytesUploaded,
        preview:       null,
      })
    })

    uppy.on("progress", progress => {
      this.progress = progress
    })

    uppy.on("upload-progress", (file, progress) => {
      this.$emit("progress", {
        id:            file.id,
        bytesTotal:    progress.bytesTotal,
        bytesUploaded: progress.bytesUploaded,
      })
    })

    uppy.on("upload-success", (file, response) => {
      this.$emit("success", {
        id:     file.id,
        medium: response.body,
      })
    })

    uppy.on("complete", () => {
      this.progress = 100
      setTimeout(() => {
        this.progress = null
        uppy.reset()
      }, 3000)
    })

    uppy.on("thumbnail:generated", (file, preview) => {
      this.$emit("preview", {
        id: file.id,
        preview,
      })
    })

    this.uppy = uppy
  },

  beforeDestroy() {
    this.uppy.close()
    this.uppy = null
  },

  methods: {
    cancelUpload(id) {
      this.uppy.removeFile(id)
      this.$emit("cancel", id)
    },
  },
}
</script>

<style>
  @import url("@uppy/core/dist/style.css");
  @import url("@uppy/drag-drop/dist/style.css");
</style>
