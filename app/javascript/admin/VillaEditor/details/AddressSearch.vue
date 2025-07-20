<template>
  <div class="panel panel-default">
    <div class="panel-heading">
      <a
          href="#"
          @click.prevent="state = state === 'closed' ? 'open' : 'closed'"
      >
        <i
            class="fa fa-fw fa-lg"
            :class="{ 'fa-plus-square-o': state === 'closed', 'fa-minus-square-o': state !== 'closed' }"
        />
        Adresse suchen
      </a>
    </div>

    <div
        v-if="state !== 'closed'"
        class="panel-body"
    >
      <input
          v-model="query"
          type="text"
          name="address-search-control"
          placeholder="Adresse suchen"
          class="form-control"
          autocomplete="off"
          @keydown.enter="search"
      >
    </div>

    <div
        v-if="state === 'error'"
        class="panel-body"
    >
      <div class="alert alert-warning">
        <i class="fa fa-warning-triangle" />
        Es ist ein Fehler aufgetreten: {{ result.error }}
      </div>
    </div>

    <div
        v-if="state === 'result' && result"
        class="panel-body"
    >
      <p>
        Folgende Adresse wurde gefunden:
      </p>
      <p>
        <strong>{{ result.street }}, {{ result.locality }}, {{ result.postal_code }},
          {{ result.region }}, {{ result.country }}</strong>
      </p>

      <div class="btn-group btn-group-sm">
        <button
            type="button"
            class="btn btn-default"
            @click="emitAndClear"
        >
          <i class="fa fa-check" />
          Adresse übernehmen
        </button>
        <a
            :href="gmapsLink"
            class="btn btn-default"
            target="_blank"
        >
          <i class="fa fa-map-marker" />
          in Google-Maps anzeigen
        </a>
      </div>
    </div>

    <div
        v-if="state !== 'closed'"
        class="panel-footer"
    >
      <button
          type="button"
          class="btn btn-default pull-right"
          @click="clear"
      >
        <i class="fa fa-times" /> Abbrechen
      </button>

      <button
          type="button"
          class="btn"
          :class="{ disabled: state === 'searching', 'btn-primary': hasQuery, 'btn-default': !hasQuery }"
          @click="search"
      >
        <i class="fa fa-search" /> Suchen
      </button>
    </div>
  </div>
</template>

<script>
import { gmapsLink } from "./maps"
import Utils from "../../../intervillas-drp/utils"

const URL = "/api/admin/address_completions.json"

export default {
  data() {
    return {
      query:  "",
      state:  "closed",
      result: null,
    }
  },

  computed: {
    hasQuery() {
      return !!(this.query && this.query.replace(/\s+/g, "").length)
    },

    gmapsLink() {
      if (this.result === null) {
        return
      }
      return gmapsLink(this.result)
    },
  },

  methods: {
    search() {
      if (!this.hasQuery || this.state === "searching") {
        return
      }

      this.state = "searching"

      Utils.requestJSON("POST", URL, { query: this.query })
        .then(data => {
          this.result = data
          this.state = data.error ? "error" : "result"
        })
    },

    clear() {
      this.query = ""
      this.result = null
    },

    emitAndClear() {
      this.$emit("address", this.result)
      this.clear()
    },
  },
}
</script>
