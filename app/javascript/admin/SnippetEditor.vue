<template>
  <p
      v-if="state === 'loading'"
      class="alert alert-info"
  >
    <i class="fa fa-spinner fa-spin" />
    Bitte warten, Daten werden geladen…
  </p>

  <MarkdownEditor
      v-else-if="state === 'content-edit'"
      v-model="attributes[`${fsContent}_content_md`]"
      :title="`Schnipsel auf ${fsContent === 'de' ? 'deutsch' : 'englisch'}`"
      @close="toggleContentEdit(false)"
  />

  <form
      v-else
      class="form-horizontal form-compact"
      @submit.prevent
  >
    <div
        class="form-group"
        :class="{ 'has-error': hasError('key') }"
    >
      <label
          class="col-sm-3 control-label"
          for="snippet_key"
      >Identifikator</label>
      <div class="col-sm-9">
        <input
            id="snippet_key"
            v-model="attributes.key"
            type="text"
            class="form-control"
        >
        <span class="help-block">
          Templates suchen Schnipsel anhand eines genau spezifizierten Namens. Wird dieser
          geändert, kann das Template den Schnipsel ggf. nicht mehr finden, und zeigt
          anstelle des hier definierten Inhalts gar nichts an.
        </span>
        <span
            v-for="(err, i) in errors.key"
            :key="i"
            class="help-block"
            v-text="err"
        />
      </div>
    </div>

    <div
        class="form-group"
        :class="{ 'has-error': hasError('title') }"
    >
      <label
          class="col-sm-3 control-label"
          for="snippet_title"
      >Beschreibung</label>
      <div class="col-sm-9">
        <input
            id="snippet_title"
            v-model="attributes.title"
            type="text"
            class="form-control"
        >
        <span class="help-block">
          kurze Beschreibung, z.B. wo dieser Schnipsel überall auftaucht
        </span>
        <span
            v-for="(err, i) in errors.title"
            :key="i"
            class="help-block"
            v-text="err"
        />
      </div>
    </div>

    <div
        class="form-group"
        :class="{ 'has-error': hasError('de_content_md') || hasError('en_content_md') }"
    >
      <label class="col-sm-3 control-label">Texte</label>

      <div class="col-sm-9">
        <div class="row">
          <div class="col-sm-6">
            <a
                href="#"
                class="btn btn-xxs btn-default pull-right"
                @click.prevent="toggleContentEdit('de')"
            >
              <i class="fa fa-arrows-alt" />
              Vollbild mit Vorschau
            </a>
            <label class="control-label" for="snippet_de_content_md">
              <span class="fi fi-de" />
              Text auf deutsch
            </label>
            <textarea
                id="snippet_de_content_md"
                ref="contentInputDE"
                v-model.trim="attributes.de_content_md"
                class="no-resize form-control"
                rows="5"
                style="max-height: 20em"
            />
            <span
                v-for="(err, i) in errors.de_content_md"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>

          <div class="col-sm-6">
            <a
                href="#"
                class="btn btn-xxs btn-default pull-right"
                @click.prevent="toggleContentEdit('en')"
            >
              <i class="fa fa-arrows-alt" />
              Vollbild mit Vorschau
            </a>
            <label
                class="control-label"
                for="snippet_en_content_md"
            >
              <span class="fi fi-us" />
              Text auf englisch
            </label>
            <textarea
                id="snippet_en_content_md"
                ref="contentInputEN"
                v-model.trim="attributes.en_content_md"
                class="no-resize form-control"
                rows="5"
                style="max-height: 20em"
            />
            <span
                v-for="(err, i) in errors.en_content_md"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="row mt-5 mb-5">
      <div class="col-sm-9 col-sm-offset-3">
        <div
            v-if="stateWas === 'saving' && hasErrors"
            class="alert alert-danger"
        >
          Beim Speichern sind Fehler aufgetreten:

          <dl class="dl-horizontal">
            <template v-for="(errs, field) in errors">
              <dt :key="field">
                {{ field | detailName }}
              </dt>
              <dd
                  v-for="(err, i) in errs"
                  :key="`${field}-${i}`"
                  v-text="err"
              />
            </template>
          </dl>
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
        <a
            href="/admin/snippets"
            class="ml50 btn btn-default"
        >Abbrechen</a>
      </div>
    </div>
  </form>
</template>

<script>
import autosize from "autosize"
import MarkdownEditor from "./MarkdownEditor.vue"
import Utils from "../intervillas-drp/utils"
import { has } from "../lib/has"

const DEFAULT_ATTRIBUTES = {
  key:           null,
  title:         null,
  de_content_md: null,
  en_content_md: null,
}

const DETAIL_BITS = {
  key:           { label: "Identifikator" },
  title:         { label: "Beschreibung" },
  de_content_md: { label: "Text (deutsch)" },
  en_content_md: { label: "Text (englisch)" },
}

export default {
  components: {
    MarkdownEditor,
  },

  filters: {
    detailName(det) {
      if (has(DETAIL_BITS, det)) {
        return DETAIL_BITS[det].label
      }
      return det
    },
  },

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

      // endpoints are used for server-communicate (see save/reset)
      loadEndpoint:  { url: this.endpoint, method: "get" },
      storeEndpoint: { url: null, method: null },
    }
  },

  computed: {
    hasErrors() {
      return Object.keys(this.errors).length > 0
    },
  },

  watch: {
    state(newState) {
      if (newState === "ready") {
        this.$nextTick(() => {
          const { contentInputDE, contentInputEN } = this.$refs
          autosize(contentInputDE)
          autosize(contentInputEN)
        })
      } else {
        const { contentInputDE, contentInputEN } = this.$refs
        autosize.destroy(contentInputDE)
        autosize.destroy(contentInputEN)
      }
    },
  },

  beforeMount() {
    this.reset()
  },

  methods: {
    // opens MarkdownEditor (id = de/en), or closes it (id = false)
    toggleContentEdit(identifier) {
      switch (identifier) {
      case "de":
      case "en":
        this.setState("content-edit")
        this.fsContent = identifier
        this.help = "content"
        break
      default:
        this.setState("ready")
        this.help = null
        break
      }
    },

    hasError(attrName) {
      return has(this.errors, attrName) && this.error[attrName].length > 0
    },

    save() {
      this.setState("saving")

      const { url, method } = this.storeEndpoint
      Utils.requestJSON(method, url, { snippet: this.attributes })
        .then(data => this._onData(data))
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

      let { attributes, endpoint, errors } = data
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
      this.setState("ready")
    },

    setState(s) {
      this.stateWas = this.state
      this.state = s
    },
  },
}
</script>
