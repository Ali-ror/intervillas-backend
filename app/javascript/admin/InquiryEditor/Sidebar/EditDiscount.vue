<template>
  <div class="modal hidden-print" tabindex="-1">
    <div class="modal-dialog">
      <form class="modal-content form-horizontal edit-discount-modal" @submit.prevent="save">
        <div class="modal-header">
          <button
              type="button"
              class="close"
              data-dismiss="modal"
          >
            <i class="fa fa-times" />
          </button>
          <h4 class="modal-title" v-text="t('label')" />
        </div>

        <div v-if="discount" class="modal-body">
          <div class="form-group">
            <label
                class="control-label col-sm-4"
                v-text="t('category')"
            />
            <div class="col-sm-8">
              <p class="form-control-static">
                {{ translate(discount.subject, { scope: "shared.discount.subjects" }) }}
              </p>
            </div>
          </div>

          <div class="form-group">
            <label class="control-label col-sm-4" v-text="t('dates')" />
            <div class="col-sm-8">
              <RangePicker
                  :start-date="discount.start_date"
                  :end-date="discount.end_date"
                  :start-date-input-name="false"
                  :end-date-input-name="false"
                  @change="onSelectDates"
              >
                <template #display="display">
                  <div v-if="display.start && display.end" class="input-group">
                    <span class="form-control">{{ formatDate(display.start) }}</span>
                    <span class="input-group-addon" style="border-width:1px 0">–</span>
                    <span class="form-control"> {{ formatDate(display.end) }}</span>
                    <span class="input-group-addon">
                      <i class="fa fa-calendar" />
                    </span>
                  </div>

                  <div v-else class="input-group">
                    <span class="form-control text-muted">
                      <span class="text-muted">{{ translate("drp.label.please_select") }}</span>
                    </span>
                    <span class="input-group-addon">
                      <i class="fa fa-calendar" />
                    </span>
                  </div>
                </template>
              </RangePicker>

              <span v-if="dates" class="help-block">
                {{ t("apply_booking_dates") }}:
                <a href="#" @click.prevent="applyDates(dates)">
                  {{ formatDateRange(dates) }}
                </a>
              </span>
            </div>
          </div>

          <div class="form-group">
            <label class="control-label col-sm-4" for="discount_value">
              {{ t("discount") }}
            </label>

            <div class="col-sm-8">
              <div class="input-group">
                <input
                    id="discount_value"
                    v-model.number="discount.value"
                    type="number"
                    step="1"
                    class="form-control"
                    @change="floorDiscountValue"
                >
                <span class="input-group-addon">%</span>
              </div>

              <span class="help-block">{{ t("discount_hint") }}</span>
            </div>
          </div>

          <table v-if="discount.subject === 'high_season'" class="table table-condensed table-striped">
            <tfoot v-if="highSeasons === null || highSeasons.length === 0">
              <tr>
                <td colspan="4" class="text-center p-2">
                  <em v-if="highSeasons === null" class="text-muted">
                    {{ t("high_season_loading") }}
                  </em>
                  <em v-else-if="highSeasons.length === 0" class="text-muted">
                    {{ t("high_season_not_found") }}
                  </em>
                </td>
              </tr>
            </tfoot>

            <template v-else>
              <thead>
                <tr>
                  <th v-text="t('high_season')" />
                  <th v-text="t('high_season_dates')" />
                  <th v-text="t('high_season_overlap')" />
                  <th />
                </tr>
              </thead>

              <tbody>
                <tr v-for="hs of highSeasons" :key="hs.id">
                  <td>{{ hs.name }}</td>
                  <td>{{ formatDateRange(hs) }}</td>
                  <td>{{ hs.overlap }}</td>
                  <td class="text-right">
                    <button
                        type="button"
                        class="btn btn-xxs"
                        :class="datesMatchHighSeason(hs) ? 'btn-primary' : 'btn-default'"
                        @click.prevent="applyDates(hs)"
                    >
                      <i class="fa fa-arrow-up" />
                      {{ t("apply_dates") }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </template>
          </table>
        </div>

        <div class="modal-footer d-flex flex-row align-items-center">
          <span class="text-left text-muted mr-3" v-text="t('reload_hint')" />

          <button
              type="button"
              class="ml-auto btn btn-default"
              data-dismiss="modal"
              :disabled="saving"
              v-text="translate('generic.cancel')"
          />
          <button
              type="button"
              class="btn btn-primary"
              :disabled="saving"
              @click.prevent="save"
          >
            <i v-if="saving" class="fa fa-spinner fa-spin" />
            {{ translate("generic.save") }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import { RangePicker } from "@digineo/date-range-picker"
import { makeDate, formatDate, formatDateRange } from "../../../lib/DateFormatter"
import Utils from "../../../intervillas-drp/utils"
import { Discount } from "./discount"
import qs from "qs"
import { format } from "date-fns"
import { translate } from "@digineo/vue-translate"

const t = key => translate(key, { scope: "inquiry_editor.sidebar.discounts" })

const ymd = date => format(date, "yyyy-MM-dd")

export default {
  components: {
    RangePicker,
  },

  props: {
    dates:   { type: Object, default: null },
    villaId: { type: [String, Number], default: null },
  },

  /**
   * @return {{
   *  discount: Discount?
   * }}
   */
  data() {
    return {
      discount:    null,
      highSeasons: null,
      saving:      false,
    }
  },

  mounted() {
    this._modal = $(this.$el)
      .modal({ show: false })
      .on("hidden.bs.modal", () => {
        this.discount = null
        this.highSeasons = null
      })
  },

  methods: {
    formatDate,
    formatDateRange,
    translate,
    t,

    show(discount) {
      this.discount = new Discount(Utils.dup(discount))
      this.highSeasons = null
      this.saving = false
      if (this.discount.subject === "high_season") {
        this.fetchHighSeasons()
      }

      this._modal.modal("show")
    },

    hide() {
      this._modal.modal("hide")
    },

    floorDiscountValue() {
      this.discount.value = Math.floor(this.discount.value || 0)
    },

    async save() {
      // update database
      this.saving = true
      await this.discount.save()

      // update discount table
      this.$emit("change-discount", this.discount)

      // refresh price table
      document.dispatchEvent(new CustomEvent("change-discount", {
        bubbles: false,
        detail:  {
          discount: this.discount,
        },
      }))

      this.hide()
    },

    onSelectDates([start_date, end_date]) {
      this.discount.start_date = start_date
      this.discount.end_date = end_date
    },

    applyDates({ start_date, end_date }) {
      this.discount.start_date = start_date
      this.discount.end_date = end_date
    },

    async fetchHighSeasons() {
      const { dates: { start_date, end_date }, villaId } = this,
            params = qs.stringify({ start_date: ymd(start_date), end_date: ymd(end_date) }),
            url = `/api/admin/villas/${villaId}/high_seasons?${params}`,
            data = await Utils.fetchJSON(url)

      this.highSeasons = data.map(hs => {
        hs.start_date = makeDate(hs.start_date)
        hs.end_date = makeDate(hs.end_date)
        return hs
      })
    },

    datesMatchHighSeason({ start_date, end_date }) {
      const { discount: { start_date: s, end_date: e } } = this
      return s.valueOf() === start_date.valueOf()
        && e.valueOf() === end_date.valueOf()
    },
  },
}
</script>
