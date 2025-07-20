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
        <div class="row">
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
                  :disabled="readOnly"
                  @input="requestClearing"
              />
            </ErrorWrapper>
          </div>
        </div>

        <template v-if="!readOnly">
          <BoatFields
              v-if="inquiry.boat_inquiry && !inquiry.boat_inquiry._destroy"
              v-model="$v.inquiry.boat_inquiry.$model"
              :validations="$v.inquiry.boat_inquiry"
              @changed:price-relevant="requestClearing"
              @remove="removeBoatInquiry()"
          />

          <div v-else class="row">
            <div class="col-md-12">
              <button
                  class="btn btn-default mt-4"
                  type="button"
                  @click="addBoatInquiry()"
              >
                <i class="fa fa-plus" />
                {{ t("inquiry.boat.add") }}
              </button>
            </div>
          </div>
        </template>
      </fieldset>

      <fieldset class="mt-4">
        <legend v-text="t('traveler.label')" />

        <ul v-if="readOnly">
          <li v-for="(n, cat) of travelerCountByCategory" :key="cat">
            {{ n }} &times; {{ t(`traveler.categories.${cat}`) }}
          </li>
        </ul>
        <template v-else>
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
                  :key="traveler.id || `t-${i}`"
                  :villa-id="inquiry.villa_inquiry.villa_id"
                  :inquiry-id="inquiry.id"
                  :value="traveler"
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
                v-if="$v.inquiry.villa_inquiry.travelers.$error && !$v.inquiry.villa_inquiry.travelers.minLength"
                class="text-warning"
                v-text="t('inquiry.no_enough_travelers')"
            />

            <button
                type="button"
                class="btn btn-default pull-right"
                @click="addTraveler"
            >
              <i class="fa fa-user-plus" />
              {{ t("traveler.add") }}
            </button>
          </p>
        </template>
      </fieldset>

      <NoteMailHints
          v-bind="changes"
          :skip="skipNotification"
          @change="skipNotification = !skipNotification"
      />

      <div v-if="['id', 'dates'].includes(changes.villa)" class="form-group">
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
              :disabled="readOnly || !submittable"
              :title="!submittable && t('inquiry.saving_no_possible')"
              v-text="t('inquiry.save')"
          />

          <span v-if="savingFailed" class="text-danger">
            <i class="fa fa-times" />
            {{ t("inquiry.saving_failed") }} ({{ savingFailed }})
          </span>
        </div>
      </div>
    </form>

    <PriceTable
        ref="priceTable"
        :read-only="readOnly"
        v-model="inquiry.clearing"
        :clearing-params="clearingParams"
        :currency="inquiry.currency"
        @invalid="submittable = false"
        @valid="submittable = true"
    >
      <template #at-end-of-table>
        <EnergyCostFields
            v-model="$v.inquiry.villa_inquiry.energy_cost_calculation.$model"
            :read-only="readOnly"
            :preset="villaECCPreset"
        />
      </template>
    </PriceTable>
  </div>
</template>

<script>
import TravelerFields from "./TravelerFields.vue"
import NoteMailHints from "./NoteMailHints.vue"
import VillaSelectOption from "./VillaSelectOption.vue"
import Common from "./Common"

import { newInquiryValidation, mustBeTrue } from "./Validations"

import { translate } from "@digineo/vue-translate"
import EnergyCostFields from "./EnergyCostFields.vue"
const t = key => translate(key, { scope: "inquiry_editor" })

export default {
  components: {
    TravelerFields,
    NoteMailHints,
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
    return v
  },

  data() {
    return {
      savingFailed:     false,
      checkedDiscounts: false,

      inquiry: {
        id: null,

        villa_inquiry: {
          inquiry_id: null,
          villa_id:   null,
          start_date: null,
          end_date:   null,
          travelers:  [{
            first_name: null,
            last_name:  null,
            born_on:    null,
            start_date: null,
            end_date:   null,
            removed:    null,
          }],
          energy_cost_calculation: null,
        },

        boat_inquiry: {
          inquiry_id: null,
          boat_id:    null,
          start_date: null,
          end_date:   null,
          _destroy:   null,
        },

        clearing: {},
      },
    }
  },

  computed: {
    travelerCountByCategory() {
      return this.inquiry.villa_inquiry.travelers.reduce((g, traveler) => {
        const { price_category: cat } = traveler
        if (cat) {
          g[cat] || (g[cat] = 0)
          g[cat]++
        }
        return g
      }, {})
    },
  },

  methods: {
    translate,
    t,
  },
}
</script>
