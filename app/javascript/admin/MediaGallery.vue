<template>
  <div
      v-if="state === 'init'"
      class="alert alert-info"
  >
    <i class="fa fa-spinner fa-spin" />
    Lade Daten, bitte warten&hellip;
  </div>

  <div
      v-else-if="state === 'error'"
      class="alert alert-danger"
  >
    <i class="fa fa-exclamation-triangle" />
    {{ errorMessage }}
  </div>

  <div v-else class="row">
    <div :class="largeSidebar ? 'col-sm-8' : 'col-sm-9'">
      <List
          :title="title"
          :media="sortedMedia"
          :edit-id="editId"
          @reorder="onReorder"
          @edit="editId = $event"
          @updated="onUpdated"
          @close="editId = null"
          @reload="reload"
      />
    </div>

    <div :class="largeSidebar ? 'col-sm-4' : 'col-sm-3'">
      <Edit
          :medium="media[editId]"
          :image-tags="tags"
          @close="editId = null"
          @updated="onUpdated"
          @destroyed="onDestroyed"
      />

      <Upload
          v-if="!editId"
          ref="uploader"
          :accepted-files="acceptedFiles"
          :upload-url="endpoints.create"
          @start="onUploadStart"
          @preview="onUploadPreview"
          @progress="onUploadProgress"
          @success="onUploadSuccess"
          @cancel="onUploadCanceled"
      />

      <slot />
    </div>
  </div>
</template>

<script>
import List from "./MediaGallery/List.vue"
import Edit from "./MediaGallery/Edit.vue"
import Upload from "./MediaGallery/Upload.vue"
import Utils from "../intervillas-drp/utils"

export default {
  components: {
    List,
    Edit,
    Upload,
  },

  props: {
    endpoint:      { type: String, required: true },
    title:         { type: String, default: "Bilder" },
    largeSidebar:  { type: Boolean, default: false },
    acceptedFiles: {
      type:    Array,
      default: () => ([".jpeg", ".jpg", ".png"]),
    },
  },

  data() {
    return {
      state:        "init",
      errorMessage: null,

      endpoints: {
        index:   this.endpoint,
        create:  null,
        reorder: null,
      },

      media:  {}, // map of ID to medium instance
      editId: null, // ID of media currently being edited
      tags:   [], // select options (of type { id: number, text: string }[])
    }
  },

  computed: {
    sortedMedia() {
      const media = []
      Object.keys(this.media).forEach(id => {
        const m = this.media[id]
        media.push(m)
      })
      media.sort((a, b) => a.position - b.position)
      return media
    },
  },

  mounted() {
    this.reload()
  },

  methods: {
    onUploadStart(item) {
      const parts = item.filename.split(".")
      item.filename = parts.slice(0, parts.length - 1).join(".")
      item.extname = parts[parts.length - 1]

      item.de_description = null
      item.en_description = null
      item.position = Object.keys(this.media).length
      item.active = false

      this.$set(this.media, item.id, item)
    },

    onUploadPreview({ id, preview }) {
      const upload = this.media[id]
      if (upload) {
        upload.preview = preview
      }
    },

    onUploadProgress({ id, bytesTotal, bytesUploaded }) {
      const upload = this.media[id]
      if (upload) {
        upload.bytesTotal = bytesTotal
        upload.bytesUploaded = bytesUploaded
      }
    },

    onUploadSuccess({ id, medium }) {
      const upload = this.media[id]

      medium.active = upload.active
      medium.filename = upload.filename
      medium.de_description = upload.de_description
      medium.en_description = upload.en_description
      if (upload.position >= 0) {
        medium.position = upload.position
      }

      medium.recentUpload = true

      this.$delete(this.media, id)
      this.$set(this.media, medium.id, medium)
      if (this.editId === id) {
        this.editId = medium.id
      }
    },

    onUploadCanceled(id) {
      this.deleteMedium(id)
    },

    onDestroyed(id) {
      if (this.editId === id) {
        this.editId = null
      }
      if (this.media[id].type === "upload") {
        this.$refs.uploader.cancelUpload(id)
      } else {
        this.deleteMedium(id)
      }
    },

    deleteMedium(id) {
      if (this.editId === id) {
        this.editId = null
      }

      this.$delete(this.media, id)
    },

    onUpdated(id, data) {
      this.$set(this.media, data.id, data)
    },

    onReorder() {
      const sorted_medium_ids = this.sortedMedia
        .filter(m => m.type !== "upload") // ignore active uploads
        .map(m => m.id)
      Utils.postJSON(this.endpoints.reorder, { sorted_medium_ids })
    },

    reload() {
      this.media = {}

      Utils.fetchJSON(this.endpoints.index).then(data => {
        this.endpoints.create = data.create_url
        this.endpoints.reorder = data.reorder_url

        for (let i = 0, len = data.media_items.length; i < len; ++i) {
          const medium = data.media_items[i]
          this.$set(this.media, medium.id, medium)
        }
        if (this.editId && !this.media[this.editId]) {
          this.editId = null
        }
        if (data.image_tags) {
          this.tags = data.image_tags
            .map(([text, id]) => ([text, id, text.toLocaleLowerCase()]))
            .sort((a, b) => a[2].localeCompare(b[2]))
            .map(([text, id, _sortby]) => ({ id, text }))
        }

        this.state = "loaded"
      })
    },
  },
}
</script>
