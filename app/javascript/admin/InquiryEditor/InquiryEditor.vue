<template>
  <Loading v-if="view === 'loading'"/>
  <UiError v-else-if="view === 'error'" :error-message="errorMessage"/>

  <div v-else>
    <div
        v-if="flash"
        class="alert alert-success"
        v-text="flash"
    />

    <form class="form-horizontal" @submit="onSubmit">
      <fieldset>
        <legend v-text="t('inquiry.objects')" />
        <div class="form-group">
          <div class="col-md-6">
            <ErrorWrapper :errors="$v.inquiry.villa_inquiry.villa_id">
              <label for="inquiry-villa">
                {{ t("inquiry.villa.label") }}

                <abbr :title="t('inquiry.villa.prices_info').join('\n\n')">
                  <i class="fa fa-question-circle text-info" />
                </abbr>
              </label>
              <UiSelect
                  id="inquiry-villa"
                  v-model="$v.inquiry.villa_inquiry.villa_id.$model"
                  :placeholder="translate('generic.please_select')"
                  :options="villaSelectOptions"
                  :reduce="opt => opt.id"
                  :template="VillaSelectOption"
                  @input="onChangeVilla"
              />
            </ErrorWrapper>
          </div>

          <div class="col-md-6 vi-period">
            <label v-text="t('inquiry.range')" />
            <ErrorWrapper :errors="$v.inquiry.villa_inquiry.start_date">
              <VillaInquiryPicker
                  :inquiry-id="inquiry.id"
                  :villa-id="inquiry.villa_inquiry.villa_id"
                  :start-date.sync="start_date"
                  :end-date.sync="end_date"
                  @change="requestClearing"
              />
            </ErrorWrapper>
          </div>
        </div>

        <BoatFields
            v-if="inquiry.boat_inquiry && !inquiry.boat_inquiry._destroy"
            v-model="$v.inquiry.boat_inquiry.$model"
            :validations="$v.inquiry.boat_inquiry"
            @changed:price-relevant="requestClearing"
            @remove="removeBoatInquiry()"
        />

        <div v-else class="row">
          <div v-if="view === 'edit'" class="col-md-12">
            <button
                class="btn btn-default"
                type="button"
                @click="addBoatInquiry()"
            >
              <i class="fa fa-plus" />
              {{ t("inquiry.boat.add") }}
            </button>
          </div>
        </div>
      </fieldset>

      <fieldset
          v-if="inquiry.villa_inquiry.start_date && inquiry.villa_inquiry.end_date"
          class="mt-4"
      >
        <legend v-text="t('traveler.label')" />
        <table class="table table-striped table-condensed">
          <thead>
            <tr>
              <th v-text="t('traveler.first_name')" />
              <th v-text="t('traveler.last_name')" />
              <th v-text="t('traveler.category')" />
              <th v-text="t('traveler.born_on')" />
              <th v-text="t('inquiry.range')" />
              <th />
            </tr>
          </thead>
          <tbody>
            <TravelerFields
                v-for="(traveler, i) of inquiry.villa_inquiry.travelers"
                :key="traveler.id || `traveler-${i}`"
                :villa-id="inquiry.villa_inquiry.villa_id"
                :inquiry-id="inquiry.id"
                :value="traveler"
                :name-required="false"
                :price-categories="priceCategories"
                @input="setTraveler(i, $event)"
                @changed:price-relevant="requestClearing"
                @remove="removeTravelerByIndex(i)"
                @restore="restoreTravelerByIndex(i)"
            />
          </tbody>
        </table>

        <p class="text-right">
          <span
              v-if="$v.inquiry.villa_inquiry.travelers.$error && $v.inquiry.villa_inquiry.travelers.minLength"
              class="text-warning"
              v-text="t('inquiry.no_enough_travelers')"
          />

          <button
              class="btn btn-default"
              type="button"
              @click="addTraveler"
          >
            <i class="fa fa-user-plus" />
            {{ t("traveler.add") }}
          </button>
        </p>
      </fieldset>
      <div
          v-else
          class="alert alert-warning mt-3"
          v-text="t('inquiry.incomplete')"
      />

      <fieldset v-if="view === 'new'" class="mt-3">
        <legend v-text="t('customer.label')" />

        <div class="form-group">
          <div class="col-md-12">
            <div class="checkbox">
              <label class="control-label">
                <input
                    v-model="inquiry.external"
                    type="checkbox"
                >
                {{ t("customer.external") }}
              </label>
              <span class="help-block ml20">
                <div
                    v-for="(hint, i) in t('customer.external_hint')"
                    :key="i"
                    v-text="hint"
                />
              </span>
            </div>
          </div>
        </div>

        <div class="form-group">
          <StackedLabel
              id="email"
              :class="errorClassFor($v.inquiry.customer.email)"
              :required="!inquiry.external && !!$v.inquiry.customer.email.$params.required"
              :label="t('customer.email')"
          >
            <input
                id="email"
                v-model.trim="$v.inquiry.customer.email.$model"
                class="form-control"
                type="text"
            >
          </StackedLabel>

          <StackedLabel
              id="phone"
              :class="errorClassFor($v.inquiry.customer.phone)"
              :label="t('customer.phone')"
          >
            <input
                id="phone"
                v-model.trim="$v.inquiry.customer.phone.$model"
                class="form-control"
                type="text"
            >
          </StackedLabel>
        </div>

        <div class="form-group">
          <StackedLabel
              id="locale"
              :class="errorClassFor($v.inquiry.customer.locale)"
              :required="!!$v.inquiry.customer.locale.$params.required"
              :label="t('customer.locale.label')"
          >
            <select
                id="locale"
                v-model="$v.inquiry.customer.locale.$model"
                class="form-control"
            >
              <option
                  v-for="(v,k) of { de: t('customer.locale.de'), en: t('customer.locale.en') }"
                  :key="k"
                  :value="k"
                  v-text="v"
              />
            </select>
          </StackedLabel>

          <StackedLabel
              id="currency"
              :class="errorClassFor($v.inquiry.currency)"
              :required="!!$v.inquiry.currency.$params.required"
              :label="t('customer.currency')"
          >
            <select
                id="currency"
                v-model="$v.inquiry.currency.$model"
                class="form-control"
                @change="requestClearing"
            >
              <option
                  v-for="cur of inquiry.availableCurrencies"
                  :key="cur"
                  :value="cur"
                  v-text="cur"
              />
            </select>
          </StackedLabel>
        </div>

        <div class="form-group">
          <StackedLabel
              id="title"
              :class="errorClassFor($v.inquiry.customer.title)"
              :required="!!$v.inquiry.customer.title.$params.required"
              :label="t('customer.title.label')"
          >
            <select
                id="title"
                v-model="$v.inquiry.customer.title.$model"
                class="form-control"
            >
              <option
                  v-for="(v,k) of { Herr: t('customer.title.m'), Frau: t('customer.title.f') }"
                  :key="k"
                  :value="k"
                  v-text="v"
              />
            </select>
          </StackedLabel>

          <StackedLabel
              id="first_name"
              :class="errorClassFor($v.inquiry.customer.first_name)"
              :required="!!$v.inquiry.customer.first_name.$params.required"
              :label="t('customer.first_name')"
          >
            <input
                id="first_name"
                v-model.trim="$v.inquiry.customer.first_name.$model"
                type="text"
                class="form-control"
            >
          </StackedLabel>

          <StackedLabel
              id="last_name"
              :class="errorClassFor($v.inquiry.customer.last_name)"
              :required="!!$v.inquiry.customer.last_name.$params.required"
              :label="t('customer.last_name')"
          >
            <input
                id="last_name"
                v-model.trim="$v.inquiry.customer.last_name.$model"
                type="text"
                class="form-control"
            >
          </StackedLabel>
        </div>
      </fieldset>

      <div v-if="view === 'edit' && ['id', 'dates'].includes(changes.villa)" class="form-group">
        <ErrorWrapper class="col-sm-12 checkbox" :errors="$v.checkedDiscounts">
          <label class="control-label">
            <input v-model="checkedDiscounts" type="checkbox">
            {{ t('checked_discounts') }}
          </label>
        </ErrorWrapper>
      </div>

      <div class="form-group">
        <div class="col-sm-12">
          <button
              v-if="submitting"
              type="submit"
              disabled
              class="btn btn-warning"
          >
            <i class="fa fa-circle-o-notch fa-spin" />
            {{ t("inquiry.saving") }}&hellip;
          </button>

          <button
              v-else
              type="submit"
              class="btn btn-primary"
              :disabled="!submittable"
              :title="!submittable && t('inquiry.saving_no_possible')"
              v-text="t('inquiry.save')"
          />

          <span
              v-if="savingFailed"
              class="text-danger"
          >
            <i class="fa fa-times" />
            {{ t("inquiry.saving_failed") }} ({{ savingFailed }})
          </span>
        </div>
      </div>
    </form>

    <PriceTable
        ref="priceTable"
        v-model="inquiry.clearing"
        :clearing-params="clearingParams"
        :currency="inquiry.currency"
        @invalid="submittable = false"
        @valid="submittable = true"
    >
      <template #at-end-of-table>
        <EnergyCostFields
            v-model="$v.inquiry.villa_inquiry.energy_cost_calculation.$model"
            :preset="villaECCPreset"
        />
      </template>
    </PriceTable>
  </div>
</template>

<script>
import TravelerFields from "./TravelerFields.vue"
import Common from "./Common"
import StackedLabel from "./StackedLabel.vue"
import VillaSelectOption from "./VillaSelectOption.vue"
import EnergyCostFields from "./EnergyCostFields.vue"

import { required, requiredUnless } from "vuelidate/lib/validators"
import { newInquiryValidation, mustBeTrue } from "./Validations"

import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "inquiry_editor" })

export default {
  components: {
    TravelerFields,
    StackedLabel,
    EnergyCostFields,
  },

  mixins: [Common],

  setup() {
    return { VillaSelectOption }
  },

  validations() {
    const v = newInquiryValidation(this.inquiry.boat_inquiry)

    if (["id", "dates"].includes(this.changes.villa)) {
      v.checkedDiscounts = { requiredSelection: mustBeTrue }
    }
    if (this.inquiry.customer) {
      v.inquiry.customer = {
        locale:     { required },
        title:      { required },
        first_name: { required },
        last_name:  { required },
        email:      { required: requiredUnless(inquiry => inquiry.external) },
        phone:      {},
      }
      v.inquiry.currency = { required }
    }
    return v
  },

  data() {
    return {
      savingFailed:     false,
      checkedDiscounts: false,

      inquiry: {
        id:                  null,
        currency:            "EUR",
        availableCurrencies: ["EUR", "USD"],
        external:            false,
        travel_insurance:    "unknown",

        villa_inquiry: {
          inquiry_id:              null,
          villa_id:                null,
          start_date:              null,
          end_date:                null,
          travelers:               [],
          energy_cost_calculation: null,
        },

        clearing: {
          total_rents: {
            value:    0,
            currency: "EUR",
          },
        },

        customer: {
          locale:     "de",
          title:      null,
          first_name: null,
          last_name:  null,
          email:      null,
          phone:      null,
        },
      },
    }
  },

  watch: {
    "inquiry.external": "requestClearing",
  },

  methods: {
    translate,
    t,

    onChangeVilla(villaId) {
      // XXX: this.villa is not recomputed, yet
      const vid = +villaId,
            { currencies, energy_cost_calculation: ecc } = this.villas?.find(v => v.id === vid) || {}

      if (currencies?.length) {
        this.inquiry.availableCurrencies = currencies
        if (!currencies.includes(this.inquiry.currency)) {
          this.inquiry.currency = currencies[0]
        }
      }
      if (ecc && this.canChangeInquiryECC()) {
        // update inquiry, unless inquiry is legacy or has overriden value
        this.inquiry.villa_inquiry.energy_cost_calculation = ecc
      }

      this.requestClearing()
    },

    errorClassFor(v) {
      if (v.$error) {
        return "has-error"
      }
      return undefined
    },
  },
}
</script>
