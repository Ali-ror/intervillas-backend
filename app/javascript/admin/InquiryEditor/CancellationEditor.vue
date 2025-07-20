<template>
  <Loading v-if="view === 'loading'"/>
  <UiError v-else-if="view === 'error'" :error-message="errorMessage"/>

  <div v-else>
    <div
        v-if="flash"
        class="alert alert-success"
        v-text="flash"
    />

    <fieldset>
      <legend v-text="t('inquiry.objects')" />
      <table class="table table-striped table-condensed">
        <tbody>
          <tr>
            <th v-text="t('inquiry.villa.label')" />
            <td v-text="inquiry.villa_inquiry.villa_name" />
            <td v-text="formatDateRange(inquiry.villa_inquiry)" />
          </tr>

          <tr v-if="inquiry.boat_inquiry">
            <th v-text="t('inquiry.boat.label')" />
            <td v-text="inquiry.boat_inquiry.name" />
            <td v-text="formatDateRange(inquiry.boat_inquiry)" />
          </tr>
          <tr v-else>
            <th v-text="t('inquiry.boat.label')" />
            <td>—</td>
            <td>—</td>
          </tr>
        </tbody>
      </table>
    </fieldset>

    <fieldset class="mt-4">
      <legend v-text="t('traveler.label')" />
      <table class="table table-striped table-condensed">
        <thead>
          <tr>
            <th v-text="t('traveler.first_name')" />
            <th v-text="t('traveler.last_name')" />
            <th v-text="t('traveler.category')" />
            <th v-text="t('traveler.born_on')" />
            <th v-text="t('inquiry.range')" />
          </tr>
        </thead>
        <tbody>
          <tr v-for="traveler of inquiry.villa_inquiry.travelers" :key="traveler.id">
            <td v-text="traveler.first_name || '—'" />
            <td v-text="traveler.last_name || '—'" />
            <td v-text="t(`traveler.categories.${traveler.price_category}`)" />
            <td v-text="traveler.born_on ? formatDate(traveler.born_on) : '—'" />
            <td v-text="formatDateRange(traveler)" />
          </tr>
        </tbody>
      </table>
    </fieldset>

    <form class="form-horizontal" @submit.prevent="onSubmit">
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

          <span v-if="savingFailed" class="text-danger">
            <i class="fa fa-times" />
            {{ t("inquiry.saving_failed") }} ({{ savingFailed }})
          </span>
        </div>
      </div>

      <PriceTable
          ref="priceTable"
          :read-only="readOnly"
          v-model="inquiry.clearing"
          :clearing-params="clearingParams"
          :currency="inquiry.currency"
          @invalid="submittable = false"
          @valid="submittable = true"
      />
    </form>
  </div>
</template>

<script>
import Common from "./Common"
import Utils from "../../intervillas-drp/utils"
import { formatDate, formatDateRange } from "../../lib/DateFormatter"
import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "inquiry_editor" })

export default {
  mixins: [Common],

  data() {
    return {
      savingFailed: false,

      inquiry: {
        id: null,

        villa_inquiry: {
          inquiry_id: null,
          villa_id:   null,
          start_date: null,
          end_date:   null,
          travelers:  [],
        },

        boat_inquiry: {
          inquiry_id: null,
          boat_id:    null,
          start_date: null,
          end_date:   null,
        },

        clearing: {},
      },
    }
  },

  methods: {
    t,
    formatDate,
    formatDateRange,

    async onSubmit(ev) {
      ev.preventDefault()
      this.savingFailed = false
      this.submitting = true

      const inquiry = Utils.dup(this.inquiry)
      inquiry.villa_inquiry_attributes = { skip_notification: true }
      delete inquiry.villa_inquiry

      if (inquiry.boat_inquiry) {
        inquiry.boat_inquiry_attributes = { skip_notification: true }
        delete inquiry.boat_inquiry
      }

      delete inquiry.customer

      inquiry.clearing_items_attributes = [
        ...inquiry.clearing.other_clearing_items,
        ...inquiry.clearing.deposits,
        ...inquiry.clearing.rentable_clearings.flatMap(rc => rc.rents),
      ]
      delete inquiry.clearing

      try {
        const data = await Utils.requestJSON("PATCH", `/api/admin/inquiries/${this.inquiry.id}.json`, { inquiry })
        if (data.errors) {
          this.inquiry.errors = data.errors
          this.savingFailed = t("common.remote_validation_failed")
          this.submitting = false
        } else {
          this._updateDataFromRemote(data.inquiry)
          this.villas = data.villas
          this.savingFailed = false
          this.flash = t("common.saved_successfully")
          setTimeout(() => this.flash = null, 15000)
        }
      } catch (err) {
        this._handleErrorFromRemote(err)
      }
    },
  },
}
</script>
