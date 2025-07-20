<template>
  <form action="#" @submit.prevent>
    <div class="row">
      <div class="col-sm-5 col-md-3">
        <h3 class="page-header">
          Status
        </h3>
        <div class="form-group">
          <div class="checkbox" :class="formGroupClass('active')">
            <label>
              <input v-model="$v.villa.active.$model" type="checkbox"> aktiv?
              <span class="help-block">nur aktive Villen können gebucht werden</span>

              <div v-if="incompleteItems" class="alert fa-alert alert-warning">
                <i class="fa fa-exclamation-triangle" />
                Bevor die Villa aktiviert werden kann, müssen folgende Elemente vorhanden
                sein: {{ incompleteItems.join(", ") }}.
              </div>
            </label>
          </div>

          <div class="checkbox" :class="formGroupClass('buyable')">
            <label>
              <input v-model="$v.villa.buyable.$model" type="checkbox"> zu verkaufen?
              <span class="help-block">wird derzeit nicht verwendet</span>
            </label>
          </div>

          <div class="form-group" :class="formGroupClass('minimum_booking_nights')">
            <label for="villa_minimum_booking_nights" class="control-label">Mindestbuchungsdauer</label>
            <div class="input-group">
              <input
                  id="villa_minimum_booking_nights"
                  v-model.number="$v.villa.minimum_booking_nights.$model"
                  type="number"
                  min="3"
                  class="form-control"
              >
              <span class="input-group-addon">Nächte</span>
            </div>
            <span
                v-for="(e, i) in errorsFor('minimum_booking_nights')"
                :key="i"
                class="help-block"
                v-text="e"
            />
            <span v-if="villa.minimum_booking_nights > 14" class="help-block">
              Die Mindestbuchungsdauer über Weihnachten beträgt ebenfalls
              {{ villa.minimum_booking_nights }} Nächte.
            </span>
          </div>

          <div class="form-group" :class="formGroupClass('minimum_people')">
            <label for="villa_minimum_people" class="control-label">Mindestpersonenzahl</label>
            <input
                id="villa_minimum_people"
                v-model.number="$v.villa.minimum_people.$model"
                type="number"
                min="2"
                :disabled="hasChildPrices"
                class="form-control"
            >
            <span
                v-for="(e, i) in errorsFor('minimum_people')"
                :key="i"
                class="help-block"
                v-text="e"
            />
            <span v-if="hasChildPrices" class="help-block">
              Änderung nicht möglich, solange Kinder-Preise vorhanden sind.
            </span>
            <span v-if="villa.bedCount === 0" class="help-block">
              <i class="fa fa-exclamation-triangle" />
              Für diese Villa sind bisher
              <strong>noch keine Betten</strong>
              vorhanden!
            </span>
            <span v-else-if="villa.minimum_people > villa.bedCount" class="help-block">
              <i class="fa fa-exclamation-triangle" />
              Für diese Villa sind bisher nur
              <strong v-text="pluralize(villa.bedCount, 'Bett', 'Betten')" />
              vorhanden!
            </span>
          </div>
        </div>

        <h3 class="page-header">
          Routing
        </h3>
        <p class="help-block">
          Auf welchen Domains ist diese Villa sichtbar?
        </p>
        <div class="form-group" :class="formGroupClass('domain_ids')">
          <div
              v-for="(sel, id) in villa.domains"
              :key="id"
              class="checkbox"
          >
            <label>
              <input
                  v-model.number="$v.villa.domain_ids.$model"
                  type="checkbox"
                  :value="id"
              >
              {{ domain(id).name }}
            </label>
          </div>
          <div
              v-for="(e, i) in errorsFor('domain_ids')"
              :key="i"
              class="help-block"
              v-text="e"
          />
        </div>
      </div>

      <div class="col-sm-7 col-md-5">
        <h3 class="page-header">
          Name
        </h3>
        <div class="form-group" :class="formGroupClass('name')">
          <label for="villa_name" class="control-label">Name</label>
          <input
              id="villa_name"
              v-model="$v.villa.name.$model"
              type="text"
              class="form-control"
          >
          <span
              v-for="(e, i) in errorsFor('name')"
              :key="i"
              class="help-block"
              v-text="e"
          />
        </div>

        <div class="row">
          <div class="col-sm-5">
            <div class="form-group" :class="formGroupClass('living_area')">
              <label for="villa_living_area" class="control-label">Wohnfläche</label>
              <div class="input-group">
                <input
                    id="villa_living_area"
                    v-model="$v.villa.living_area.$model"
                    type="text"
                    class="form-control"
                >
                <span class="input-group-addon">m<sup>2</sup></span>
              </div>
              <span
                  v-for="(e, i) in errorsFor('living_area')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>

          <div class="col-sm-7">
            <div class="form-group" :class="formGroupClass('pool_orientation')">
              <label for="villa_pool_orientation" class="control-label">Ausrichtung Pool</label>
              <select
                  id="villa_pool_orientation"
                  v-model="$v.villa.pool_orientation.$model"
                  class="form-control"
              >
                <option value="">
                  Bitte wählen
                </option>
                <option
                    v-for="dir in cardinalDirections"
                    :key="dir"
                    :value="dir"
                    v-text="translate(`villas.cardinal_directions.${dir}`)"
                />
              </select>
              <span
                  v-for="(e, i) in errorsFor('pool_orientation')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-sm-5">
            <div class="form-group" :class="formGroupClass('build_year')">
              <label for="villa_build_year" class="control-label">Baujahr</label>
              <input
                  id="villa_build_year"
                  v-model="$v.villa.build_year.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('build_year')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
          <div class="col-sm-7">
            <div class="form-group" :class="formGroupClass('last_renovation')">
              <label for="villa_last_renovation" class="control-label">Zuletzt renoviert</label>
              <input
                  id="villa_last_renovation"
                  v-model="$v.villa.last_renovation.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('last_renovation')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-sm-5">
            <div class="form-group" :class="formGroupClass('safe_code')">
              <label for="villa_code" class="control-label">Safe-Code</label>
              <input
                  id="villa_code"
                  v-model="$v.villa.safe_code.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('safe_code')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
          <div class="col-sm-7">
            <div class="form-group" :class="formGroupClass('phone')">
              <label for="villa_phone" class="control-label">Telefonnummer</label>
              <input
                  id="villa_phone"
                  v-model="$v.villa.phone.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('phone')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
        </div>

        <p class="help-block">
          Safe-Code und Telefonnummer werden in die Reiseantrittsmail eingefügt.
          Diese Eingabefelder sind nicht für Text-Schnipsel gedacht, und werden
          <strong>nicht</strong> in die Sprache des Kunden übersetzt!
        </p>

        <div class="form-group" :class="formGroupClass('manager_id')">
          <label for="villa_manager_id" class="control-label">Hausverwaltung</label>
          <UiSelect
              id="villa_manager_id"
              v-model.number="$v.villa.manager_id.$model"
              clearable
              label="name"
              placeholder="Bitte wählen"
              :options="contactOptions"
              :reduce="o => o.id"
              :template="ContactOption"
          />
          <span
              v-for="(e, i) in errorsFor('manager_id')"
              :key="i"
              class="help-block"
              v-text="e"
          />
        </div>

        <div class="form-group" :class="formGroupClass('owner_id')">
          <label for="villa_owner_id" class="control-label">Eigentümer</label>
          <UiSelect
              id="villa_owner_id"
              v-model.number="$v.villa.owner_id.$model"
              clearable
              label="name"
              placeholder="Bitte wählen"
              :options="contactOptions"
              :reduce="o => o.id"
              :template="ContactOption"
          />
          <span
              v-for="(e, i) in errorsFor('owner_id')"
              :key="i"
              class="help-block"
              v-text="e"
          />
        </div>

        <h3 class="page-header">
          Externe Kalender
        </h3>
        <table class="table table-condensed table-striped">
          <thead>
            <tr>
              <th>
                URL
                <abbr title="http:// oder https:// URL zu iCal-Daten, für extern definierte Termin-Blockierungen">
                  <i class="fa fa-info-circle text-info" />
                </abbr>
              </th>
              <th>
                Name
                <abbr title="Name oder kurzer Kommentar (taucht in E-Mails auf)">
                  <i class="fa fa-info-circle text-info" />
                </abbr>
              </th>
              <th />
            </tr>
          </thead>

          <tbody>
            <tr v-for="(cal, i) in $v.villa.calendars.$each.$iter" :key="cal.$model.id || i">
              <td :class="formGroupClass('calendars.$each.$iter', i, 'url')">
                <input
                    v-model="cal.url.$model"
                    class="form-control"
                    :disabled="cal.$model._destroy"
                    type="text"
                    placeholder="URL"
                >
                <small
                    v-for="(e, ei) in errorsFor('calendars.$each.$iter', i, 'url')"
                    :key="ei"
                    class="help-block"
                    v-text="e"
                />
              </td>
              <td :class="formGroupClass('calendars.$each.$iter', i, 'name')">
                <input
                    v-model="cal.name.$model"
                    class="form-control"
                    :disabled="cal.$model._destroy"
                    type="text"
                    placeholder="Name"
                >
                <small
                    v-for="(e, ei) in errorsFor('calendars.$each.$iter', i, 'name')"
                    :key="ei"
                    class="help-block"
                    v-text="e"
                />
              </td>
              <td>
                <button
                    v-if="cal.$model._destroy"
                    class="btn btn-xxs btn-default"
                    type="button"
                    @click.prevent="cal.$model._destroy = false"
                >
                  <i class="fa fa-refresh" /> behalten
                </button>
                <button
                    v-else
                    class="btn btn-xxs btn-danger"
                    type="button"
                    @click.prevent="cal.$model._destroy = true"
                >
                  <i class="fa fa-trash" /> löschen
                </button>
              </td>
            </tr>

            <tr v-if="villa.calendars.length === 0">
              <td class="text-center" colspan="3">
                <em class="text-muted">Keine externen Kalender definiert.</em>
              </td>
            </tr>
          </tbody>

          <tfoot>
            <tr>
              <td colspan="3">
                <button
                    class="btn btn-xxs btn-default"
                    type="button"
                    @click.prevent="addCalendar"
                >
                  <i class="fa fa-plus" /> Kalender hinzufügen
                </button>
              </td>
            </tr>
          </tfoot>
        </table>
      </div>

      <div class="col-sm-6 col-md-4">
        <h3 class="page-header">
          Adresse
          <a
              v-if="hasGeoCoordinates"
              :href="gmapsLink"
              target="_blank"
              class="pull-right btn btn-default btn-xxs"
          >
            <i class="fa fa-external-link" />
            in Google-Maps anzeigen
          </a>
        </h3>

        <div class="form-group" :class="formGroupClass('street')">
          <label for="villa_street" class="control-label">Straße</label>
          <input
              id="villa_street"
              v-model="$v.villa.street.$model"
              type="text"
              class="form-control"
          >
          <span
              v-for="(e, i) in errorsFor('street')"
              :key="i"
              class="help-block"
              v-text="e"
          />
        </div>

        <div class="row">
          <div class="col-sm-6">
            <div class="form-group" :class="formGroupClass('locality')">
              <label for="villa_locality" class="control-label">Ort</label>
              <input
                  id="villa_locality"
                  v-model="$v.villa.locality.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('locality')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
          <div class="col-sm-6">
            <div class="form-group" :class="formGroupClass('postal_code')">
              <label for="villa_postal_code" class="control-label">Postleitzahl</label>
              <input
                  id="villa_postal_code"
                  v-model="$v.villa.postal_code.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('postal_code')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-sm-6">
            <div class="form-group" :class="formGroupClass('region')">
              <label for="villa_region" class="control-label">Region</label>
              <input
                  id="villa_region"
                  v-model="$v.villa.region.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('region')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
          <div class="col-sm-6">
            <div class="form-group" :class="formGroupClass('country')">
              <label for="villa_country" class="control-label">Land</label>
              <input
                  id="villa_country"
                  v-model="$v.villa.country.$model"
                  type="text"
                  class="form-control"
              >
              <span
                  v-for="(e, i) in errorsFor('country')"
                  :key="i"
                  class="help-block"
                  v-text="e"
              />
            </div>
          </div>
        </div>

        <AddressSearch @address="onAddress"/>
      </div>
    </div>

    <slot
        name="buttons"
        :payload-fn="buildPayload"
        :active="!wasClean"
    />
  </form>
</template>

<script>
import Common from "./common"
import { gmapsLink } from "./details/maps"
import { Contact } from "./models"
import { CARDINAL_DIRECTIONS } from "../../cardinal_directions"
import UiSelect from "../../components/UiSelect.vue"
import AddressSearch from "./details/AddressSearch.vue"
import ContactOption from "./ContactOption.vue"

import { validationMixin } from "vuelidate"
import {
  countryCode,
  integer,
  minLength,
  minValue,
  required,
  requiredIf,
} from "./validators"

const isNumber = n => !isNaN(Number(n))

const hasPrice = (prices, category) => {
  return prices
    && !prices._destroy
    && prices[category] != null
    && prices[category].value != null
    && prices[category].value >= 0
}

export default {
  components: {
    AddressSearch,
    UiSelect,
  },

  mixins: [Common, validationMixin],

  setup() {
    return { ContactOption }
  },

  validations() {
    return {
      villa: {
        active:                 {},
        buyable:                {},
        name:                   { required },
        minimum_booking_nights: { required, integer, minValue: minValue(3) }, // ABSOLUTE_MINIMUM_DAYS
        minimum_people:         { required, integer, minValue: minValue(2) },
        build_year:             { },
        last_renovation:        { },
        safe_code:              { required },
        phone:                  { required },
        manager_id:             { required },
        owner_id:               {},
        living_area:            { required, integer, minValue: minValue(0) },
        pool_orientation:       { required },
        street:                 { required },
        postal_code:            { required },
        locality:               { required },
        region:                 { required },
        country:                { required, countryCode },
        domain_ids:             { minLength: minLength(1) },

        calendars: {
          $each: {
            url: {
              required: requiredIf(function(calendar) {
                return !calendar._destroy
              }),
            },
            name: {},
          },
        },
      },
    }
  },

  computed: {
    cardinalDirections() {
      return CARDINAL_DIRECTIONS
    },

    contactOptions() {
      return Contact.all()
    },

    hasChildPrices() {
      const { villa_price_eur, villa_price_usd } = this.villa

      return hasPrice(villa_price_eur, "children_under_6")
        || hasPrice(villa_price_eur, "children_under_12")
        || hasPrice(villa_price_usd, "children_under_6")
        || hasPrice(villa_price_usd, "children_under_12")
    },

    hasGeoCoordinates() {
      return isNumber(this.villa.latitude) && isNumber(this.villa.longitude)
    },

    gmapsLink() {
      if (this.hasGeoCoordinates) {
        const v = this.villa
        return gmapsLink({
          street:      v.street,
          locality:    v.locality,
          postal_code: v.postal_code,
          region:      v.region,
          country:     v.country,
          latitude:    v.latitude,
          longitude:   v.longitude,
        })
      }
      return null
    },

    incompleteItems() {
      const { descriptions, villa_price_eur, villa_price_usd } = this.villa
      const missing = []

      if (!descriptions || !descriptions.description) {
        missing.push("Beschreibungstext (DE/EN)")
      } else {
        const { de, en } = descriptions.description
        if (de == null || de.trim() === "") {
          missing.push("Beschreibungstext (DE)")
        }
        if (en == null || en.trim() === "") {
          missing.push("Beschreibungstext (EN)")
        }
      }

      const noPrices = p => !hasPrice(p, "base_rate")
      if (noPrices(villa_price_eur) && noPrices(villa_price_usd)) {
        missing.push("Personenpreise")
      }
      return missing.length ? missing : null
    },
  },

  methods: {
    onAddress(address) {
      const v = this.villa
      v.street = address.street
      v.locality = address.locality
      v.postal_code = address.postal_code
      v.region = address.region
      v.country = address.country
      v.latitude = address.latitude
      v.longitude = address.longitude
    },

    addCalendar() {
      this.villa.addCalendar()
    },

    pluralize(count, singular, plural) {
      return count === 1
        ? `${count} ${singular}`
        : `${count} ${plural}`
    },
  },
}
</script>
