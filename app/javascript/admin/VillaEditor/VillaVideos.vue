<template>
  <div v-if="state === 'init'" class="alert alert-info">
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
    <div class="col-sm-8">
      <Draggable
          v-if="videos.length"
          v-model="videos"
          class="list-group villa-video-list-group"
          ghost-class="disabled"
          draggable=".item"
          handle=".handle"
          @end="onReorder"
      >
        <form
            v-for="(video, index) in videos"
            :key="video.id"
            class="list-group-item item"
            @change="save(index)"
            @submit.prevent="save(index)"
        >
          <span class="handle text-muted">
            <i class="fa fa-lg fa-ellipsis-v" />
            <i class="fa fa-lg fa-ellipsis-v" />
          </span>

          <input
              v-model.trim="video.video_url"
              type="text"
              class="form-control"
          >

          <ToggleSwitch
              class="text-center"
              :active="video.active"
              @click="toggleActive(index)"
          />

          <input
              v-model.trim="video.de_description"
              type="text"
              class="form-control"
          >
          <input
              v-model.trim="video.en_description"
              type="text"
              class="form-control"
          >

          <span class="actions">
            <a
                v-if="true"
                href="#"
                title="Vorschaubild"
                @click.prevent="showThumbnailModal(index)"
            >
              <i
                  class="fa fa-fw fa-lg fa-file-image-o"
                  :class="video.thumbnail_url ? 'text-info' : 'text-muted'"
              />
            </a>

            <a
                v-if="video.video_url"
                href="#"
                title="Vorschau"
                @click.prevent="showPreviewModal(index)"
            >
              <i class="fa fa-fw fa-lg fa-eye text-info" />
            </a>
            <i
                v-else
                title="Vorschau nicht möglich: URL fehlt"
                class="fa fa-fw fa-lg fa-eye-slash text-muted"
            />

            <a
                href="#"
                title="Video löschen"
                @click.prevent="deleteVideo(index)"
            >
              <i class="fa fa-fw fa-lg fa-trash text-danger" />
            </a>
          </span>
        </form>

        <template #header>
          <div class="list-group-item text-muted">
            <span class="handle" />
            <strong>YouTube-URL</strong>
            <strong class="text-center">Aktiv?</strong>
            <strong><span class="fi fi-de" /> Titel</strong>
            <strong><span class="fi fi-us" /> Titel</strong>
            <span class="actions" />
          </div>
        </template>
      </Draggable>

      <div v-else class="alert alert-warning">
        Noch keine Videos hinterlegt.
      </div>

      <p class="text-right">
        <button
            class="btn btn-default btn-sm"
            type="button"
            @click.prevent="addVideo"
        >
          <i class="fa fa-plus" />
          Video hinzufügen
        </button>
      </p>
    </div>

    <aside class="col-sm-4">
      <h2>Informationen</h2>
      <p>
        Hier können externe Videos von YouTube verlinkt werden.
      </p>

      <h3>YouTube-URL</h3>
      <p>
        Wir benötigen einen Link zum Video in einer der foldenen Formen:
      </p>
      <ul>
        <li><code>https://www.youtube.com/watch?v=VIDEOID</code></li>
        <li><code>https://youtu.be/VIDEOID</code></li>
      </ul>
      <p>
        Codes zum Einbetten (<code>&lt;script...&lt;/script&gt;</code>)
        werden <strong>nicht</strong> unterstützt.
      </p>

      <h3>Aktiv?</h3>
      <p>
        Einzelne Videos können zeitweise (oder permanent) deaktiviert werden,
        ohne es löschen zu müssen. Dazu einfach auf die
        <i class="fa fa-toggle-off" />/<i class="fa fa-toggle-on text-success" />-Icons
        klicken.
      </p>

      <h3>Titel</h3>
      <p>
        Über dem Video wird der Titel in der jeweiligen Sprache angezeigt.
      </p>
      <ul>
        <li>
          Wenn nur ein Titel (entweder bei DE oder EN) eingetragen ist,
          wird derselbe Titel unter beiden Sprachen angezeigt.
        </li>
        <li>
          Wenn gar kein Titel angebegen wurde, wird stattdessen nur "Video"
          angezeigt.
        </li>
      </ul>
      <p>
        Ein eindeutiger und kurzer Titel ist sinnvoll, den Namen der Villa
        hier nochmal einzutragen jedoch nicht.
      </p>

      <h3>Sortierung</h3>
      <p>
        Das oberste (aktive) Video ist auf der Villa-Seite zuerst sichtbar,
        danach folgen die anderen Videos. Die Reihenfolge kann mit der Maus
        durch Klicken-und-Verschieben auf dem
        <i class="fa fa-ellipsis-v" />&thinsp;<i class="fa fa-ellipsis-v" />-Icon
        geändert werden.
      </p>
    </aside>

    <VModal
        v-if="previewVideo"
        name="preview"
        class="bg-dark"
        :width="1280"
        :height="720"
        @before-close="onCloseModal"
    >
      <iframe
          :src="previewVideo.embedUrl"
          frameborder="0"
          allow="autoplay; encrypted-media"
          allowfullscreen
      />
    </VModal>

    <VModal
        v-if="thumbnailVideo"
        name="thumbnail"
        :width="900"
        :height="560"
        @before-close="onCloseModal"
    >
      <div class="d-flex flex-column h-100">
        <div class=" d-flex align-items-center justify-content-center flex-grow-1">
          <img
              v-if="thumbnailVideo.thumbnail_url"
              :src="thumbnailVideo.thumbnail_url"
              :style="{ opacity: thumbnailRefreshing ? 0.8 : 1 }"
              class="img-thumbnail"
          >
          <em v-else class="text-muted">
            <i class="fa fa-times" /> Vorschaubild nicht verfügbar
          </em>
        </div>

        <div class="p-3 text-right">
          <button
              type="button"
              class="btn btn-sm btn-default"
              :disabled="thumbnailRefreshing"
              @click.prevent="refreshThumbnail()"
          >
            <i
                class="fa"
                :class="{
                  'fa-refresh': !thumbnailRefreshing,
                  'fa-spinner': thumbnailRefreshing,
                  'fa-pulse': thumbnailRefreshing,
                }"
            />
            Vorschaubild neu laden
          </button>
        </div>
      </div>
    </VModal>
  </div>
</template>

<script>
import Draggable from "vuedraggable"
import ToggleSwitch from "../ToggleSwitch.vue"
import Utils from "../../intervillas-drp/utils"
import Common from "./common"
import { embedUrl } from "../../lib/youtube"

class VillaVideo {
  constructor({ id, position, active, de_description, en_description, url, video_url, thumbnail_url, refresh_url }) {
    if (id) {
      this.id = id
    } else {
      this.id = -(new Date().valueOf())
    }

    this.position = position
    this.active = active || false
    this.de_description = de_description || ""
    this.en_description = en_description || ""
    this.url = url // update/delete URL
    this.video_url = video_url || ""
    this.thumbnail_url = thumbnail_url || ""
    this.refresh_url = refresh_url || ""
  }

  get embedUrl() {
    return embedUrl(this.video_url)
  }
}

export default {
  components: {
    Draggable,
    ToggleSwitch,
  },

  mixins: [Common],

  data() {
    return {
      state:        "init",
      errorMessage: null,
      videos:       [], // VillaVideo instances
      preview:      null, // index into videos

      thumbnail:           null, // index into videos
      thumbnailRefreshing: false,
      thumbnailMessage:    null,

      endpoints: {
        index:   this.api.videos.endpoint,
        create:  null,
        reorder: null,
      },
    }
  },

  computed: {
    previewVideo() {
      const idx = this.preview
      return idx == null ? null : this.videos[idx]
    },

    thumbnailVideo() {
      const idx = this.thumbnail
      return idx == null ? null : this.videos[idx]
    },
  },

  mounted() {
    this.reload()
  },

  methods: {
    async reload() {
      this.state === "init"
      this.errorMessage = null
      this.videos = {}

      try {
        const { media_items, create_url, reorder_url } = await Utils.fetchJSON(this.endpoints.index)
        this.endpoints.create = create_url
        this.endpoints.reorder = reorder_url
        this.videos = media_items.map(v => new VillaVideo(v))
        this.state = "loaded"
      } catch (err) {
        this.state = "error"
        this.errorMessage = err.message
      }
    },

    onReorder() {
      const sorted_medium_ids = this.videos
        .filter(m => m.id > 0) // skip new videos
        .map(m => m.id)
      Utils.postJSON(this.endpoints.reorder, { sorted_medium_ids })
    },

    async save(index) {
      const { id, active, position, de_description, en_description, url, video_url } = this.videos[index],
            payload = {
              active,
              position,
              de_description,
              en_description,
              data: { url: video_url },
            }

      let resp
      if (id > 0) {
        resp = await Utils.putJSON(url, { medium: payload })
      } else {
        resp = await Utils.postJSON(this.endpoints.create, { medium: payload })
      }

      this.videos.splice(index, 1, new VillaVideo(resp))
    },

    addVideo() {
      this.videos.push(new VillaVideo({
        position: this.videos.length,
      }))
    },

    async deleteVideo(index) {
      const v = this.videos[index]
      if (v.id > 0) {
        if (!confirm("Video-Verlinkung wirklich löschen?")) {
          return
        }

        await Utils.deleteJSON(v.url)
      }

      this.videos.splice(index, 1)
    },

    async refreshThumbnail() {
      if (!this.thumbnailVideo || this.thumbnailRefreshing) {
        return // nothing selected or already working
      }

      this.thumbnailRefreshing = true

      try {
        const resp = await Utils.postJSON(this.thumbnailVideo.refresh_url, null)
        this.videos.splice(this.thumbnail, 1, new VillaVideo(resp))
      } catch (err) {
        console.error("failed to refresh thumbnail", err)
      } finally {
        this.thumbnailRefreshing = false
      }
    },

    toggleActive(index) {
      this.videos[index].active = !this.videos[index].active
      this.save(index)
    },

    showPreviewModal(id) {
      this.preview = id
      this.onShowModal("preview")
    },

    showThumbnailModal(id) {
      this.thumbnail = id
      this.onShowModal("thumbnail")
    },

    onShowModal(name) {
      this.$nextTick(() => {
        document.querySelector("body").style.overflow = "hidden"
        this.$modal.show(name)
      })
    },

    onCloseModal() {
      this.preview = null
      this.thumbnail = null
      document.querySelector("body").style.overflow = ""
    },
  },
}
</script>

<style lang="scss">
.villa-video-list-group {
  .ghost {
    opacity: 0.5;
    background: #aaa;
  }

  .list-group-item {
    display: grid;
    // handle, URL, active?, de desc, en desc, actions
    grid-template-columns: 20px 2fr 50px 1fr 1fr 80px;
    gap: 3px 6px;
    padding: 3px 6px;
    align-items: center;

    .handle {
      cursor: ns-resize;
    }

    .actions {
      white-space: nowrap;
      text-align: right;
    }
  }
}
</style>
