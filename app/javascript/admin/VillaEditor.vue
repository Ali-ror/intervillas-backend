<template>
  <div class="row villa-editor">
    <VillaNavigation
        :id="hasPublicUrl ? villa.id : null"
        :new-record="isNewRecord"
        :index="api.index"
    />

    <div class="col-sm-10">
      <h1 class="page-header" v-text="subheading" />

      <Loading v-if="state === 'init'"/>

      <div
          v-if="unsavedHint"
          class="well well-sm fa-alert"
      >
        <i class="fa fa-floppy-o pull-left" />
        <p class="text-danger">
          <strong>Warnung:</strong> Ungespeicherte Änderungen gefunden.
        </p>
        <p>
          <button
              class="btn btn-xs btn-primary"
              @click.prevent="saveUnsaved()"
          >
            speichern
          </button>
          oder
          <button
              class="btn btn-xs btn-warning"
              @click.prevent="resetUnsaved()"
          >
            verwerfen
          </button>
          und zur Seite
          <em v-text="unsavedHint.meta.linkLabel" />
          fortfahren.
        </p>
      </div>

      <div
          v-if="flash"
          class="alert"
          :class="`alert-${flash.type}`"
      >
        <a
            href="#"
            class="close"
            @click.prevent="flash = null"
        ><i class="fa fa-times" /></a>
        {{ flash.message }}
      </div>

      <KeepAlive v-if="state === 'loaded'">
        <RouterView
            ref="currentSection"
            :villa="villa"
            :api="api"
            @save="saveData"
            @reset="loadData()"
            @hint-unsaved="hintUnsaved"
        >
          <template #buttons="{ active }">
            <hr class="hr-sm">
            <div class="row mb-5">
              <div class="col-sm-9 col-sm-offset-3">
                <button
                    class="btn"
                    type="button"
                    :class="active ? 'btn-primary' : 'btn-default'"
                    @click.prevent="saveData()"
                >
                  Speichern
                </button>

                <button
                    class="btn btn-default ml-1"
                    type="button"
                    :disabled="!active"
                    @click.prevent="resetUnsaved()"
                >
                  Änderungen verwerfen
                </button>
              </div>
            </div>
          </template>
        </RouterView>
      </KeepAlive>
    </div>
  </div>
</template>

<script>
import VueRouter from "vue-router"
import { translate } from "@digineo/vue-translate"

import Utils from "../intervillas-drp/utils"
import { has } from "../lib/has"
import Loading from "./Loading.vue"

import { Villa } from "./VillaEditor/models"
import VillaAdditionalProperties from "./VillaEditor/VillaAdditionalProperties.vue"
import VillaBoats from "./VillaEditor/VillaBoats.vue"
import VillaDetails from "./VillaEditor/VillaDetails.vue"
import VillaImages from "./VillaEditor/VillaImages.vue"
import VillaNavigation from "./VillaEditor/VillaNavigation.vue"
import VillaPannellumn from "./VillaEditor/VillaPannellums.vue"
import VillaPrices from "./VillaEditor/VillaPrices.vue"
import VillaReviews from "./VillaEditor/VillaReviews.vue"
import VillaTags from "./VillaEditor/VillaTags.vue"
import VillaTours from "./VillaEditor/VillaTours.vue"
import VillaVideos from "./VillaEditor/VillaVideos.vue"

const bindEndpoint = (method, url) => Utils.requestJSON.bind(Utils, method, url)

let router = null
if (/^\/admin\/villas\/(?:\d+([^/]+)?\/edit|new)/.test(window.location.pathname)) {
  /**
   * Creates a VueRouter route.
   *
   * @param {String} path Path name
   * @param {Vue} component The Vue component to show
   * @param {String} icon FontAwesome icon name
   * @param {String} i18nkey Translation key for sidebar link and section title.
   */
  const route = function(path, component, icon, i18nkey) {
    return { path, component, meta: { icon, i18nkey } }
  }

  router = new VueRouter({
    routes: [
      route("/", VillaDetails, "fa-home", "villa"),
      route("/tags", VillaTags, "fa-tags", "tags"),
      route("/additional-props", VillaAdditionalProperties, "fa-cogs", "additional_props"),
      route("/prices", VillaPrices, "fa-eur", "prices"),
      route("/images", VillaImages, "fa-picture-o", "images"),
      route("/tours", VillaTours, "fa-camera-retro", "tours"),
      route("/pannellums", VillaPannellumn, "fa-camera", "pannellums"),
      route("/videos", VillaVideos, "fa-play", "videos"),
      route("/boats", VillaBoats, "fa-ship", "boats"),
      route("/reviews", VillaReviews, "fa-star-half-o", "reviews"),
    ],
  })
}

export default {
  components: {
    VillaNavigation,
    Loading,
  },

  router,

  props: {
    endpointUrl: { type: String, required: true },
    indexUrl:    { type: String, required: true },
  },

  data() {
    return {
      state:       "init",
      villa:       null,
      unsavedHint: null, // inhibited route to navigate to (because of validation problems)

      flash: null,

      api: {
        self:  null, // properly change URL when sucessfully saved a new record
        load:  null, // JSON endpoint for fetching Villa data
        store: null, // JSON endpoint for storing Villa data (create + update)
        index: null, // URL to index page

        images:     null, // endpoint for AdminMediaGallery (images)
        tours:      null, // endpoint for AdminMediaGallery (tours v1)
        pannellums: null, // endpoint for AdminMediaGallery (tours v2)
        videos:     null, // endpoint for Videos (currently external Youtube links)
        reviews:    null, // endpoint for ReviewEditor
      },
    }
  },

  computed: {
    isNewRecord() {
      return !this.villa || this.villa.newRecord
    },

    hasPublicUrl() {
      return !this.isNewRecord && this.villa.active
    },

    subheading() {
      const subheading = [(this.villa?.name || "Villa")]

      let sectionLabel = ""
      if (this.state === "loaded") {
        const { label, section_alias } = translate(this.$route.meta.i18nkey, { scope: "villa_editor.nav" })
        sectionLabel = section_alias || label
      }

      subheading.push("•", translate(this.isNewRecord ? "create" : "edit", {
        scope: "villa_editor.section_heading",
        label: sectionLabel,
      }))
      return subheading.join(" ")
    },
  },

  watch: {
    $route() {
      this.flash = null
    },
  },

  mounted() {
    this.api.index = this.indexUrl
    this.api.load = bindEndpoint("GET", this.endpointUrl)
    this.loadData()
  },

  methods: {
    loadData() {
      return this.api.load().then(data => {
        const { attributes, collections, endpoint } = data.payload
        this.villa = Villa.build(attributes, collections)
        this.resetCurrentSection()
        this.updateEndpoints(endpoint)

        this.state = "loaded"
        this.anyDirty = false
      })
    },

    saveData() {
      if (!this.canSave()) {
        this.flash = {
          type:    "warning",
          message: "Speichern nicht möglich: das Formular enthält noch Fehler.",
        }
        return
      }

      this.flash = null

      const villa = this.$refs.currentSection.buildPayload()
      return this.api.store({ villa }).then(data => {
        this.flash = data.flash
        if (has(data, "payload")) {
          this.villa = Villa.build(data.payload.attributes)
          this.resetCurrentSection()
          this.updateEndpoints(data.payload.endpoint)
        }
        if (has(data, "errors")) {
          this.villa.errors = data.errors
        }
      }).catch(err => {
        this.flash = {
          type:    "danger",
          message: "Speichern fehlgeschlagen: das Formular enthält ungültige Eingaben.",
        }
      }).finally(() => {
        window.scrollTo(0, 0)
      })
    },

    hintUnsaved(to) {
      this.unsavedHint = to
    },

    saveUnsaved() {
      const promise = this.saveData()
      if (!promise) {
        return
      }

      promise.then(() => {
        if (this.unsavedHint) {
          const { flash } = this
          this.$router.push(this.unsavedHint).then(() => this.flash = flash)
          this.unsavedHint = null
        }
      })
    },

    resetUnsaved() {
      this.loadData().then(() => {
        if (this.unsavedHint) {
          this.$router.push(this.unsavedHint)
          this.unsavedHint = null
        }
      })
    },

    canSave() {
      if (this.$refs.currentSection) {
        return this.$refs.currentSection.isValid()
      }
      return false
    },

    resetCurrentSection() {
      if (this.$refs.currentSection) {
        this.$refs.currentSection.reset()
      }
    },

    updateEndpoints(endpoints) {
      const { method, url } = endpoints.villa
      this.api.store = bindEndpoint(method, url)

      this.api.images = endpoints.images
      this.api.tours = endpoints.tours
      this.api.pannellums = endpoints.pannellums
      this.api.reviews = endpoints.reviews
      this.api.videos = endpoints.videos

      if (this.api.self !== endpoints.self) {
        // if this URL changed, we've sucessfully saved a new record, and
        // we need to fixup the actual window.location.pathname
        window.history.replaceState({}, "", endpoints.self + "#" + this.$route.fullPath)
        this.api.self = endpoints.self
      }
    },
  },
}
</script>

<!--
  note: style intentionally non-scoped
        (also applies to child components)
-->
<style>
.villa-editor h1 i,
.villa-editor h2 i,
.villa-editor h3 i {
  padding-right: 0;
}

.villa-editor .form-group .checkbox label {
  color: inherit;
}

.villa-editor textarea {
  resize: vertical;
}
</style>
