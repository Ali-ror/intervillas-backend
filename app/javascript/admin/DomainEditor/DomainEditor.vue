<template>
  <p v-if="state === 'loading'" class="alert alert-info">
    <i class="fa fa-spinner fa-spin" />
    Bitte warten, Daten werden geladen…
  </p>

  <div v-else class="row">
    <div v-if="state === 'content-edit'" class="col-sm-9">
      <MarkdownEditor
          v-model="attributes[`${fsContent}_content_md`]"
          :title="`SEO-Text auf ${fsContent === 'de' ? 'deutsch' : 'englisch'}`"
          @close="toggleContentEdit(false)"
      />
    </div>

    <div v-else class="col-sm-9">
      <DomainEditorForm
          v-model="attributes"
          :relations="relations"
          :errors="errors"
          @contentEdit="toggleContentEdit"
      />

      <div class="row mb-5">
        <div class="col-sm-9 col-sm-offset-3">
          <div v-if="stateWas === 'saving' && hasErrors" class="alert alert-danger">
            Beim Speichern sind Fehler aufgetreten:

            <ErrorList :errors="errors"/>
          </div>

          <button
              class="btn btn-primary"
              type="button"
              @click.prevent="save"
          >
            Speichern
          </button>
          <button
              class="ml10 btn btn-default"
              type="button"
              :disabled="!attributes.id"
              @click.prevent="reset(true)"
          >
            Zurücksetzen
          </button>
          <a class="ml50 btn btn-default" href="/admin/domains">Abbrechen</a>
        </div>
      </div>
    </div>

    <div class="col-sm-3">
      <DomainEditorHelp />
    </div>
  </div>
</template>

<script>
import DomainEditorForm from "./DomainEditorForm.vue"
import DomainEditorHelp from "./DomainEditorHelp.vue"
import MarkdownEditor from "../MarkdownEditor.vue"
import Utils from "../../intervillas-drp/utils"
import { has } from "../../lib/has"
import { DETAIL_BITS } from "./_texts"

import Vue from "vue"
import Vuex, { mapState, mapMutations } from "vuex"
Vue.use(Vuex)

const DEFAULT_ATTRIBUTES = {
  name:                null,
  default:             false,
  brand_name:          null,
  multilingual:        false,
  interlinked:         false,
  theme:               "intervillas",
  tracking_code:       null,
  de_content_md:       null,
  de_meta_title:       null,
  de_meta_description: null,
  en_content_md:       null,
  en_meta_title:       null,
  en_meta_description: null,
  logo_path:           null,
  logo_name:           null,
  boat_ids:            [],
  villa_ids:           [],
  page_ids:            [],
  partials:            [],
}

function detailName(det) {
  if (has(DETAIL_BITS, det)) {
    return DETAIL_BITS[det].label
  }
  return det
}

export default {
  components: {
    DomainEditorForm,
    DomainEditorHelp,
    MarkdownEditor,

    ErrorList: {
      name:       "ErrorList",
      functional: true,

      props: {
        errors: { type: Array, default: () => ([]) },
      },

      render(h, { props }) {
        const errors = Object.entries(props.errors).map(([field, errs]) => {
          return [h("dt", detailName(field)), errs.map(err => h("dd", err))]
        })

        return h("dl", { class: "dl-horizontal" }, errors)
      },
    },
  },

  store: new Vuex.Store({
    state: {
      help: null,
    },

    mutations: {
      setHelp(s, name) {
        s.help = name
      },
    },
  }),

  props: {
    endpoint: { type: String, required: true },
  },

  data() {
    return {
      state:     "loading", // loading -> ready <-> content-edit
      stateWas:  null, // previous state
      fsContent: null, // fullscreen markdown-editor content identifier ("de" or "en")

      // attributes is transmitted saved to/read from the DB
      attributes: { ...DEFAULT_ATTRIBUTES },
      errors:     {},

      // relations provide a hook for larger collections
      relations: {
        boats:    [],
        pages:    [],
        partials: [],
        villas:   [],
      },

      // API endpoints (see save/reset)
      loadEndpoint:  { url: this.endpoint, method: "get" },
      storeEndpoint: { url: null, method: null },
    }
  },

  computed: {
    ...mapState(["help"]),

    hasErrors() {
      return Object.keys(this.errors).length > 0
    },
  },

  beforeMount() {
    this.reset()
  },

  methods: {
    ...mapMutations(["setHelp"]),

    // opens MarkdownEditor (id = de/en), or closes it (id = false)
    toggleContentEdit(identifier) {
      switch (identifier) {
      case "de":
      case "en":
        this.setState("content-edit")
        this.fsContent = identifier
        this.setHelp("content")
        break
      default:
        this.setState("ready")
        this.setHelp(null)
        break
      }
    },

    // (re-) creates this.relations from this.attributes and this.collections
    //
    // ordinarily, we'd use a computed property here, but this object is
    // passed into DomainEditorForm and mutated there.
    rebuildRelations(attributes, collections) {
      const buildByID = (attr, coll) => collections[coll].map((el, i) => ({
        order: attributes[attr] ? attributes[attr].indexOf(el.id) : -1,
        pos:   i,
        ...el,
      }))

      const buildByName = (attr, coll) => collections[coll].map((name, i) => ({
        order: attributes[attr] ? attributes[attr].indexOf(name) : i, // enabled by default
        pos:   i,
        id:    name,
      }))

      this.relations = {
        boats:    buildByID("boat_ids", "boats"),
        villas:   buildByID("villa_ids", "villas"),
        pages:    buildByID("page_ids", "pages"),
        partials: buildByName("partials", "partials", true),
        themes:   buildByName("theme", "themes", true),
      }
    },

    // copies this.relations back into this.attributes
    unbuildRelations() {
      const activeIDs = rel => this.relations[rel]
        .filter(r => r.order >= 0)
        .sort((a, b) => a.order - b.order)
        .map(r => r.id)

      const unbuild = (attr, rel) => {
        this.$set(this.attributes, attr, activeIDs(rel))
      }

      unbuild("boat_ids", "boats")
      unbuild("villa_ids", "villas")
      unbuild("page_ids", "pages")
      unbuild("partials", "partials")
      this.attributes.theme = activeIDs("themes")[0]
    },

    async save() {
      this.setState("saving")
      this.unbuildRelations()

      const { url, method } = this.storeEndpoint
      try {
        const data = await Utils.requestJSON(method, url, { domain: this.attributes })
        this._onData(data)
      } catch (_err) {
        this.setState("error")
      }
    },

    reset(confirm) {
      if (confirm && !window.confirm("Es werden alle ungespeicherten Änderungen rückgängig gemacht. Fortfahren?")) {
        return
      }
      if (!this.loadEndpoint) {
        return
      }

      this.setState("loading")
      Utils.fetchJSON(this.loadEndpoint.url)
        .then(data => this._onData(data))
    },

    _onData(data) {
      if (!data) {
        return
      }

      let { attributes, collections, endpoint, errors } = data
      this.errors = errors || {}
      if (errors) {
        this.setState("ready")
        return
      }
      if (!attributes || attributes.id === null) {
        attributes = { ...DEFAULT_ATTRIBUTES }
      }

      this.attributes = attributes
      this.storeEndpoint = endpoint
      this.rebuildRelations(attributes, collections)
      this.setState("ready")
    },

    setState(s) {
      this.stateWas = this.state
      this.state = s
    },
  },
}
</script>
