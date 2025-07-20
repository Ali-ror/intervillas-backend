<template>
  <form class="form-horizontal form-compact" @submit.prevent>
    <fieldset>
      <legend>Globale Einstellungen</legend>
      <FormGroup id="domain_name" v-bind="detailData('name')">
        <input
            id="domain_name"
            v-model.trim="attributes.name"
            class="form-control"
            :disabled="attributes.default"
        >
        <span v-if="attributes.default" class="help-block">
          Dies ist die Default-Domain. Ihr Name kann nicht geändert werden.
        </span>
        <span
            v-for="(err, i) in errors.name"
            :key="i"
            class="help-block"
            v-text="err"
        />
      </FormGroup>

      <FormGroup id="domain_tracking_code" v-bind="detailData('tracking_code')">
        <input
            id="domain_tracking_code"
            v-model.trim="attributes.tracking_code"
            class="form-control"
        >
        <span class="help-block">
          Google-Analytics-Code. Hat typischerweise die Form "UA-12343589-1".
        </span>
        <span
            v-for="(err, i) in errors.tracking_code"
            :key="i"
            class="help-block"
            v-text="err"
        />
      </FormGroup>

      <FormGroup id="domain_brand_name" v-bind="detailData('brand_name')">
        <input
            id="domain_brand_name"
            v-model.trim="attributes.brand_name"
            class="form-control"
        >
        <span
            v-for="(err, i) in errors.brand_name"
            :key="i"
            class="help-block"
            v-text="err"
        />
      </FormGroup>

      <FormGroup id="domain_theme" v-bind="detailData('theme')">
        <select
            id="domain_theme"
            v-model="attributes.theme"
            class="form-control"
        >
          <option
              v-for="theme in relations.themes"
              :key="theme.id"
              :value="theme.id"
          >
            {{ theme.id }} {{ theme.id | themeHint }}
          </option>
        </select>
        <span
            v-for="(err, i) in errors.theme"
            :key="i"
            class="help-block"
            v-text="err"
        />
      </FormGroup>

      <FormGroup id="domain_multilingual" v-bind="detailData('multilingual')">
        <div class="checkbox">
          <label>
            <input v-model="attributes.multilingual" type="checkbox">
            Mehrsprachig?
          </label>
          <span v-if="attributes.multilingual" class="help-block ml20">
            Auf der Webseite wird die Sprachauswahl angeboten. Die www-Subdomain
            führt zur deutschen Seite, die en-Subdomain zur englischen Seite.
          </span>
          <span v-else class="help-block ml20">
            Es wird keine Sprachauswahl angeboten. Eine der Text-Übersetzungen (DE oder EN) muss
            leer bleiben. Alle Subdomains führen entweder zur deutsch- oder englischsprachigen
            Seite (jenachdem, welcher Text ausgefüllt wurde). Sind trotzdem beide Texte ausgefüllt,
            hat der dt. Text Vorrang.
          </span>
          <span
              v-for="(err, i) in errors.multilingual"
              :key="i"
              class="help-block ml20"
              v-text="err"
          />
        </div>
      </FormGroup>

      <FormGroup id="domain_interlink" v-bind="detailData('interlink')">
        <div class="checkbox">
          <label>
            <input v-model="attributes.interlink" type="checkbox">
            Ökosystem-Seite?
          </label>
          <span class="help-block ml20">
            Domains können Teil des «Intervilla-Ökosystems» sein. Dies sind Satelliten-Seiten,
            die aus SEO-Gründen untereinander verlinkt sind.
          </span>
          <span
              v-for="(err, i) in errors.interlink"
              :key="i"
              class="help-block ml20"
              v-text="err"
          />
        </div>
      </FormGroup>
    </fieldset>

    <fieldset>
      <legend>Startseite</legend>
      <FormGroup id="domain_html_title" v-bind="detailData('html_title')">
        <div class="row">
          <div class="col-sm-6 domain_html_title_de">
            <label class="control-label" for="domain_de_html_title">
              <span class="fi fi-de" />
              Titel auf deutsch
            </label>
            <input
                id="domain_de_html_title"
                v-model.trim="attributes.de_html_title"
                class="form-control"
            >
            <span
                v-for="(err, i) in errors.de_html_title"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
          <div class="col-sm-6 domain_html_title_en">
            <label class="control-label" for="domain_en_html_title">
              <span class="fi fi-us" />
              Titel auf english
            </label>
            <input
                id="domain_en_html_title"
                v-model.trim="attributes.en_html_title"
                class="form-control"
            >
            <span
                v-for="(err, i) in errors.en_html_title"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
        </div>
      </FormGroup>

      <FormGroup id="domain_meta_description" v-bind="detailData('meta_description')">
        <div class="row">
          <div class="col-sm-6 domain_meta_description_de">
            <label class="control-label" for="domain_de_meta_description">
              <span class="fi fi-de" />
              Beschreibung auf deutsch
            </label>
            <input
                id="domain_de_meta_description"
                v-model.trim="attributes.de_meta_description"
                class="form-control"
            >
            <span
                v-for="(err, i) in errors.de_meta_description"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
          <div class="col-sm-6 domain_meta_description_en">
            <label class="control-label" for="domain_en_meta_description">
              <span class="fi fi-us" />
              Beschreibung auf english
            </label>
            <input
                id="domain_en_meta_description"
                v-model.trim="attributes.en_meta_description"
                class="form-control"
            >
            <span
                v-for="(err, i) in errors.en_meta_description"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
        </div>
      </FormGroup>

      <FormGroup
          id="domain_partials"
          v-bind="detailData('partials')"
          @labelClick="toggleDetails('partials')"
      >
        <FormDetails
            :title="`${numEnabledPartials} von ${relations.partials.length} ausgewählt`"
            :open="openDetails.partials"
            @toggle="openDetails.partials = $event"
        >
          <ul id="domain_partials" class="list-group">
            <li
                v-for="(item, i) in orderedPartials"
                :key="item.id"
                class="list-group-item"
            >
              <div class="row">
                <ToggleSwitch
                    class="col-sm-1"
                    v-bind="itemData('partials', item)"
                    @click="toggle('partials', item)"
                />
                <div class="col-sm-9" @click="toggle('partials', item)">
                  <div class="list-group-item-heading">
                    {{ item.id | partialTitle }}
                  </div>
                  <div class="list-group-item-text text-muted">
                    {{ item.id | partialDesc }}
                  </div>
                </div>
                <div v-if="item.order >= 0" class="col-sm-2 text-right">
                  <div class="btn-group btn-group-xs">
                    <button
                        class="btn"
                        type="button"
                        title="nach oben schieben"
                        :disabled="i === 0"
                        :class="item.id === recentlyMovedPartialID ? 'btn-info' : 'btn-default'"
                        @click="movePartial(item, -1)"
                    >
                      <i class="fa fa-arrow-up" />
                    </button>
                    <button
                        class="btn"
                        type="button"
                        title="nach unten schieben"
                        :disabled="i === numEnabledPartials - 1"
                        :class="item.id === recentlyMovedPartialID ? 'btn-info' : 'btn-default'"
                        @click="movePartial(item, 1)"
                    >
                      <i class="fa fa-arrow-down" />
                    </button>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </FormDetails>
      </FormGroup>

      <FormGroup id="domain_page_heading" v-bind="detailData('page_heading')">
        <div class="row">
          <div class="col-sm-6 domain_page_heading_de">
            <label class="control-label" for="domain_de_page_heading">
              <span class="fi fi-de" />
              Überschrift auf deutsch
            </label>
            <input
                id="domain_de_page_heading"
                v-model.trim="attributes.de_page_heading"
                class="form-control"
            >
            <span
                v-for="(err, i) in errors.de_page_heading"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
          <div class="col-sm-6 domain_page_heading_en">
            <label class="control-label" for="domain_en_page_heading">
              <span class="fi fi-us" />
              Überschrift auf english
            </label>
            <input
                id="domain_en_page_heading"
                v-model.trim="attributes.en_page_heading"
                class="form-control"
            >
            <span
                v-for="(err, i) in errors.en_page_heading"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
        </div>
        <span class="help-block">wird vom Inhalte-Block "Überschrift" ausgegeben</span>
      </FormGroup>

      <FormGroup
          id="domain_slides"
          v-bind="detailData('slides')"
          @labelClick="toggleDetails('slides')"
      >
        <AdminMediaGallery
            v-if="attributes.slides_url"
            :endpoint="attributes.slides_url"
            large-sidebar
        />
        <div v-else class="alert alert-info">
          Slider-Bilder können erst eingerichtet werden, nachdem die Domain
          gespeichert wurde.
        </div>
      </FormGroup>

      <FormGroup id="domain_content" v-bind="detailData('content')">
        <div class="row">
          <div class="col-sm-6 domain_content_de">
            <a
                class="btn btn-xxs btn-default pull-right"
                href="#"
                @click.prevent="$emit('contentEdit', 'de')"
            >
              <i class="fa fa-arrows-alt" /> Vollbild mit Vorschau
            </a>
            <label class="control-label" for="domain_de_content_md">
              <span class="fi fi-de" />
              Text auf deutsch
            </label>
            <textarea
                id="domain_de_content_md"
                ref="contentInputDE"
                v-model.trim="attributes.de_content_md"
                class="no-resize form-control"
                name="domain_de_content_md"
                rows="5"
                style="max-height: 20em;"
            />
            <span
                v-for="(err, i) in errors.de_content"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
          <div class="col-sm-6 domain_content_en">
            <a
                class="btn btn-xxs btn-default pull-right"
                href="#"
                @click.prevent="$emit('contentEdit', 'en')"
            >
              <i class="fa fa-arrows-alt" />
              Vollbild mit Vorschau
            </a>
            <label class="control-label" for="domain_en_content_md">
              <span class="fi fi-us" />
              Text auf englisch
            </label>
            <textarea
                id="domain_en_content_md"
                ref="contentInputEN"
                v-model.trim="attributes.en_content_md"
                class="no-resize form-control"
                name="domain_en_content_md"
                rows="5"
                style="max-height: 20em;"
            />
            <span
                v-for="(err, i) in errors.en_content"
                :key="i"
                class="help-block"
                v-text="err"
            />
          </div>
        </div>
      </FormGroup>
    </fieldset>

    <fieldset>
      <legend>Verknüpfungen</legend>
      <FormGroup
          id="domain_pages"
          v-bind="detailData('pages')"
          @labelClick="toggleDetails('pages')"
      >
        <FormDetails
            :title="`${numEnabledPages} von ${relations.pages.length} ausgewählt`"
            :open="openDetails.pages"
            @toggle="openDetails.pages = $event"
        >
          <ul id="domain_pages" class="list-group">
            <li
                v-for="item in relations.pages"
                :key="item.id"
                class="list-group-item"
            >
              <div class="row">
                <ToggleSwitch
                    class="col-sm-1"
                    v-bind="itemData('pages', item)"
                    @click="toggle('pages', item)"
                />
                <div class="col-sm-5" @click="toggle('pages', item)">
                  {{ item.title }}<br>
                  <code>{{ item.path[0] === "/" ? "" : "/" }}{{ item.path }}</code>
                </div>
                <div class="col-sm-4" @click.prevent="toggle('pages', item)">
                  <code
                      v-if="item.name"
                      title="Name (intern)"
                      v-text="item.name"
                  />
                </div>
                <div class="col-sm-2 text-right">
                  <a
                      class="btn btn-xxs btn-default"
                      :href="`/admin/pages/${item.id}/edit`"
                      target="_blank"
                  >
                    <i class="fa fa-external-link" /> Details
                  </a>
                </div>
              </div>
            </li>
          </ul>
        </FormDetails>
      </FormGroup>

      <FormGroup
          id="domain_villas"
          v-bind="detailData('villas')"
          @labelClick="toggleDetails('villas')"
      >
        <FormDetails
            :title="`${numEnabledVillas} von ${relations.villas.length} ausgewählt`"
            :open="openDetails.villas"
            @toggle="openDetails.villas = $event"
        >
          <ul id="domain_villas" class="list-group">
            <li class="list-group-item">
              <div class="row">
                <div class="col-sm-1">
                  <a
                      href="#"
                      @click.prevent="selectAll(filteredVillas)"
                  >alle</a><br>
                  <a
                      href="#"
                      @click.prevent="selectNone(filteredVillas)"
                  >keine</a>
                </div>
                <div class="col-sm-11">
                  <div class="input-group">
                    <span class="input-group-addon"><i class="fa fa-search" /></span><input
                        v-model="villaSearch"
                        class="form-control"
                        placeholder="nach Villa-Name filtern"
                    >
                    <span v-if="villaSearch" class="input-group-btn">
                      <button
                          class="btn btn-default"
                          type="button"
                          @click="villaSearch = ''"
                      >
                        <i class="fa fa-times" />
                      </button>
                    </span>
                  </div>
                </div>
              </div>
            </li>
            <li
                v-for="item in filteredVillas"
                :key="item.id"
                class="list-group-item"
            >
              <div class="row">
                <ToggleSwitch
                    class="col-sm-1"
                    v-bind="itemData('villas', item)"
                    @click="toggle('villas', item)"
                />
                <div
                    class="col-sm-11"
                    @click.prevent="toggle('villas', item)"
                    v-text="item.name"
                />
              </div>
            </li>
          </ul>
        </FormDetails>
      </FormGroup>

      <FormGroup
          id="domain_boats"
          v-bind="detailData('boats')"
          @labelClick="toggleDetails('boats')"
      >
        <FormDetails
            :title="`${numEnabledBoats} von ${relations.boats.length} ausgewählt`"
            :open="openDetails.boats"
            @toggle="openDetails.boats = $event"
        >
          <ul id="domain_boats" class="list-group">
            <li class="list-group-item">
              <div class="row">
                <div class="col-sm-1">
                  <a
                      href="#"
                      @click.prevent="selectAll(filteredBoats)"
                  >alle</a><br>
                  <a
                      href="#"
                      @click.prevent="selectNone(filteredBoats)"
                  >keine</a>
                </div>
                <div class="col-sm-11">
                  <div class="input-group">
                    <span class="input-group-addon">
                      <i class="fa fa-search" />
                    </span>
                    <input
                        v-model="boatSearch"
                        class="form-control"
                        placeholder="nach Boat-Name filtern"
                    >
                    <span v-if="boatSearch" class="input-group-btn">
                      <button
                          class="btn btn-default"
                          type="button"
                          @click="boatSearch = ''"
                      >
                        <i class="fa fa-times" />
                      </button>
                    </span>
                  </div>
                </div>
              </div>
            </li>
            <li
                v-for="item in filteredBoats"
                :key="item.id"
                class="list-group-item"
            >
              <div class="row">
                <ToggleSwitch
                    class="col-sm-1"
                    v-bind="itemData('boats', item)"
                    @click="toggle('boats', item)"
                />
                <div
                    class="col-sm-11"
                    @click="toggle('boats', item)"
                    v-text="item.name"
                />
              </div>
            </li>
          </ul>
        </FormDetails>
      </FormGroup>
    </fieldset>
  </form>
</template>

<script>
import autosize from "autosize"
import FormDetails from "./FormDetails.vue"
import FormGroup from "./FormGroup.vue"
import ToggleSwitch from "../ToggleSwitch.vue"
import { has } from "../../lib/has"
import { PARTIAL_INFO, DETAIL_BITS } from "./_texts"

const countOrder = function(collection, attr) {
  return collection.reduce((sum, el) => sum + (el.order < 0 ? 0 : 1), 0)
}

const normalizeSearch = s =>
  s.toLocaleLowerCase().replace(/[^\w\däöü]/g, " ").trim().replace(/\s+/g, " ")

const filterCollection = (collection, searchString) => {
  if (!searchString) {
    return collection
  }

  const q = normalizeSearch(searchString)
  return collection.filter(el => normalizeSearch(el.name).includes(q))
}

export default {
  components: {
    FormDetails,
    FormGroup,
    ToggleSwitch,
  },

  filters: {
    themeHint(theme) {
      switch (theme) {
      case "intervillas":
        return "(türkis)"
      case "satellite":
        return "(orange)"
      }
    },

    partialTitle(name) {
      if (has(PARTIAL_INFO, name)) {
        return PARTIAL_INFO[name].title
      }
      return name
    },

    partialDesc(name) {
      if (has(PARTIAL_INFO, name)) {
        return PARTIAL_INFO[name].desc
      }
      return "unbekannter Inhalt"
    },
  },

  props: {
    value:     { type: Object, required: true }, // v-model
    errors:    { type: Object, default: () => ({}) },
    relations: { type: Object, required: true },
  },

  data() {
    const hasID = has(this.value, "id") && this.value.id !== null
    return {
      openDetails: {
        partials: !hasID, // open all for new records
        pages:    !hasID,
        villas:   !hasID,
        boats:    !hasID,
      },
      recentlyMovedPartialID: null,
      villaSearch:            "",
      boatSearch:             "",
    }
  },

  computed: {
    attributes() {
      return this.value
    },

    orderedPartials() {
      const byOrder = (a, b) => a.order < 0 ? 1 : b.order < 0 ? -1 : a.order - b.order
      return [...this.relations.partials].sort(byOrder).map((p, i) => {
        p.order >= 0 && (p.order = i)
        return p
      })
    },

    filteredVillas() {
      return filterCollection(this.relations.villas, this.villaSearch)
    },

    filteredBoats() {
      return filterCollection(this.relations.boats, this.boatSearch)
    },

    numEnabledPartials() {
      return countOrder(this.orderedPartials.filter(p => p.order >= 0))
    },

    numEnabledPages() {
      return countOrder(this.relations.pages)
    },

    numEnabledVillas() {
      return countOrder(this.relations.villas)
    },

    numEnabledBoats() {
      return countOrder(this.relations.boats)
    },
  },

  mounted() {
    autosize(this.$refs.contentInputDE)
    autosize(this.$refs.contentInputEN)
  },

  beforeDestroy() {
    autosize.destroy(this.$refs.contentInputDE)
    autosize.destroy(this.$refs.contentInputEN)
  },

  methods: {
    detailData(attr) {
      const bits = DETAIL_BITS[attr]
      return {
        label: bits.label,
        split: bits.split || [3, 9],
        help:  bits.help ? attr : null,
        class: {
          "has-error": has(this.errors, attr) && this.errors[attr].length > 0,
        },
      }
    },

    toggleDetails(name) {
      this.$set(this.openDetails, name, !this.openDetails[name])
    },

    movePartial({ id }, direction) {
      const index = this.relations.partials.findIndex(el => el.id === id),
            pivot = index + Math.sign(direction)

      if (pivot < 0 || pivot >= this.numEnabledPartials) {
        return // already at either end
      }

      const a = this.relations.partials[index],
            b = this.relations.partials[pivot]
      a.order = b.order + (b.order = a.order, 0)
      this.recentlyMovedPartialID = id
    },

    toggle(collection, { id }) {
      const item = this.relations[collection].find(el => el.id === id)
      if (item.order < 0) {
        item.order = this.relations[collection].length
      } else {
        item.order = -1
      }
      if (collection === "partials") {
        this.recentlyMovedPartialID = id
      }
    },

    itemData(collection, item) {
      let name = item.title || item.name || item.id
      if (collection === "partials") {
        if (has(PARTIAL_INFO, item.id)) {
          name = PARTIAL_INFO[item.id].title
        }
      }
      return {
        active: item.order >= 0,
        name,
      }
    },

    selectAll(collection) {
      collection.forEach(el => {
        if (el.order < 0) {
          el.order = el.pos
        }
      })
    },

    selectNone(collection) {
      collection.forEach(el => {
        if (el.order >= 0) {
          el.order = -1
        }
      })
    },
  },
}
</script>

<style scoped>
.list-group-item {
  padding: 3px 6px;
}
.list-group-item:hover {
  background-color: #eee;
}
td.toggle-column {
  width: 1%
}

.btn-file {
  position: relative;
  overflow: hidden;
}
.btn-file input[type=file] {
    position: absolute;
    top: 0;
    right: 0;
    min-width: 100%;
    min-height: 100%;
    font-size: 100px;
    text-align: right;
    filter: alpha(opacity=0);
    opacity: 0;
    outline: none;
    background: white;
    cursor: inherit;
    display: block;
}
</style>
