import { validationMixin } from "vuelidate"

import BoatFields from "./BoatFields.vue"
import UiError from "../../components/UiError.vue"
import ErrorWrapper from "./ErrorWrapper.vue"
import Loading from "../Loading.vue"
import PriceTable from "../PriceTable/PriceTable.vue"
import UiSelect from "../../components/UiSelect.vue"
import VillaInquiryPicker from "./VillaInquiryPicker.vue"
import TrackingChanges from "./TrackingChanges"

import { awaitSpecialDates } from "../../intervillas-drp/special-dates"
import Utils from "../../intervillas-drp/utils"
import { has } from "../../lib/has"
import { makeDate } from "../../lib/DateFormatter"
import Inconsistencies from "./inconsistencies"

import { translate } from "@digineo/vue-translate"
import { format } from "date-fns"
const t = key => translate(key, { scope: "inquiry_editor.common" })

const boat_inquiry = {
  inquiry_id: null,
  boat_id:    null,
  start_date: null,
  end_date:   null,
  name:       null,
  days:       null,
  discounts:  [],
  _destroy:   null,
}

export default {
  components: {
    BoatFields,
    UiError,
    ErrorWrapper,
    Loading,
    PriceTable,
    UiSelect,
    VillaInquiryPicker,
  },

  mixins: [
    validationMixin,
    TrackingChanges,
  ],

  props: {
    inquiryId: { type: Number, default: null },
    readOnly:  { type: Boolean, default: false },
  },

  data() {
    return {
      view:         "loading", // loading, new, edit, or error
      submitting:   true,
      submittable:  true,
      errorMessage: null,
      flash:        null,

      villas: null,

      skipNotification: false, // see {Villa,Boat}Inquiry#skip_notification
    }
  },

  watch: {
    "inquiry.villa_inquiry.start_date"() {
      // FullCalendar zum Datum springen lassen
      const ev = new CustomEvent("change.start-date", {
        bubbles: false,
        detail:  {
          start_date: this.start_date,
        },
      })
      document.dispatchEvent(ev)
    },
  },

  computed: {
    villa() {
      const { villa_id } = this.inquiry.villa_inquiry
      return this.villas?.find(v => v.id === villa_id)
    },

    villaECCPreset() {
      const { energy_cost_calculation } = this.villa || {}
      return energy_cost_calculation || "defer"
    },

    clearingParams() {
      const params = this.buildCommonClearingParams()
      params.villa.travelers = this.simplifiedTravelers()
      return params
    },

    priceCategories() {
      if (this.inquiry.villa_inquiry && this.villa) {
        const { traveler_price_categories } = this.villa
        // traveler_price_categories.{eur,usd} SHOULD have the same shape
        if (this.inquiry.currency === "USD") {
          // USD prices are either explicitly defined, or can be converted from EUR
          return traveler_price_categories.usd || traveler_price_categories.eur
        }
        // EUR prices however are never converted from USD prices
        return traveler_price_categories.eur
      }
    },

    start_date: {
      get() {
        if (!this.inquiry.villa_inquiry.start_date) {
          return null
        }
        return makeDate(this.inquiry.villa_inquiry.start_date)
      },
      set(value) {
        this.inquiry.villa_inquiry.start_date = format(value, "yyyy-MM-dd")
        this.$v.inquiry.villa_inquiry.start_date.$touch()
      },
    },

    end_date: {
      get() {
        if (!this.inquiry.villa_inquiry.end_date) {
          return null
        }
        return makeDate(this.inquiry.villa_inquiry.end_date)
      },
      set(value) {
        this.inquiry.villa_inquiry.end_date = format(value, "yyyy-MM-dd")
        this.$v.inquiry.villa_inquiry.end_date.$touch()
      },
    },

    villaSelectOptions() {
      if (Array.isArray(this.villas)) {
        return this.villas.map(v => {
          return {
            id:    v.id,
            label: v.name.trim(),
            eur:   has(v.traveler_price_categories, "eur"),
            usd:   has(v.traveler_price_categories, "usd"),
          }
        })
      }
      return []
    },

    mayRequestClearing() {
      const submitting = this.submitting
      const villa_id = this.inquiry.villa_inquiry.villa_id
      const start_date = this.inquiry.villa_inquiry.start_date
      const end_date = this.inquiry.villa_inquiry.end_date

      return !submitting && villa_id && start_date && end_date
    },
  },

  methods: {
    addTraveler() {
      const t = {
        first_name:     null,
        last_name:      null,
        start_date:     this.inquiry.villa_inquiry.start_date,
        end_date:       this.inquiry.villa_inquiry.end_date,
        price_category: "adults",
        born_on:        null,
        newRecord:      true,
        isValid:        null,
      }
      this.inquiry.villa_inquiry.travelers.push(t)
      this.$nextTick(() => this.requestClearing())
    },

    setTraveler(i, traveler) {
      this.savingFailed = false
      this.$set(this.inquiry.villa_inquiry.travelers, i, traveler)

      // siehe https://github.com/vuelidate/vuelidate/issues/492
      this.$v.inquiry.villa_inquiry.travelers.$each.$iter[i].isValid.$model = traveler.isValid
    },

    removeTravelerByIndex(index) {
      const t = this.inquiry.villa_inquiry.travelers[index]
      if (!t.id) {
        this.inquiry.villa_inquiry.travelers.splice(index, 1)
      } else {
        this.$set(t, "removed", true)
        this.$v.inquiry.villa_inquiry.travelers.$each.$iter[index].isValid.$model = true
      }

      this.requestClearing()
    },

    restoreTravelerByIndex(index) {
      const t = this.inquiry.villa_inquiry.travelers[index]
      this.$set(t, "removed", false)
      this.$v.inquiry.villa_inquiry.travelers.$each.$iter[index].isValid.$model = t.isValid

      this.requestClearing()
    },

    _withTraveler(id, cb) {
      const idx = this.inquiry.villa_inquiry.travelers.findIndex(t => t.id === id)
      if (idx >= 0) {
        cb(this.inquiry.villa_inquiry.travelers[idx], idx)
      }
    },

    simplifiedTravelers() {
      return this.inquiry.villa_inquiry.travelers.filter(t => !t.removed).map(t => ({
        price_category: t.price_category,
        start_date:     format(makeDate(t.start_date), "yyyy-MM-dd"),
        end_date:       format(makeDate(t.end_date), "yyyy-MM-dd"),
      }))
    },

    async onSubmit(ev) {
      ev.preventDefault()
      this.savingFailed = false

      this.$v.$touch()

      if (this.$v.$invalid) {
        this.savingFailed = t("local_validation_failed")
        return
      }

      this.submitting = true

      const inquiry = Utils.dup(this.inquiry)
      inquiry.travelers_attributes = inquiry.villa_inquiry.travelers.map(t => {
        if (t.removed) {
          t["_destroy"] = "1" //  rails
        }
        return t
      })
      delete inquiry.villa_inquiry["travelers"]

      inquiry.villa_inquiry_attributes = inquiry.villa_inquiry
      delete inquiry.villa_inquiry
      if (this.skipNotification) {
        inquiry.villa_inquiry_attributes.skip_notification = true
      }
      if (inquiry.boat_inquiry) {
        inquiry.boat_inquiry_attributes = inquiry.boat_inquiry
        delete inquiry.boat_inquiry
        if (this.skipNotification) {
          inquiry.boat_inquiry_attributes.skip_notification = true
        }
      }
      if (!inquiry.id) {
        inquiry.customer_attributes = inquiry.customer
      }

      delete inquiry.customer

      inquiry.clearing_items_attributes = [
        ...inquiry.clearing.other_clearing_items,
        ...inquiry.clearing.deposits,
        ...inquiry.clearing.rentable_clearings.flatMap(rc => rc.rents),
      ]
      delete inquiry.clearing

      const [method, url] = this.inquiry.id
        ? ["PATCH", `/api/admin/inquiries/${this.inquiry.id}.json`]
        : ["POST", "/api/admin/inquiries.json"]

      try {
        const data = await Utils.requestJSON(method, url, { inquiry })
        if (data.errors) {
          this.inquiry.errors = data.errors
          this.savingFailed = t("remote_validation_failed")
          this.submitting = false
        } else {
          this._updateDataFromRemote(data.inquiry)
          this.villas = data.villas
          Inconsistencies.display(data.inconsistencies)
          this.savingFailed = false
          this.flash = t("saved_successfully")
          setTimeout(() => this.flash = null, 15000)
        }
      } catch (err) {
        this._handleErrorFromRemote(err)
      }
    },

    _handleErrorFromRemote(err) {
      if (err.response) {
        this.errorMessage = err.response.statusText
        console.log(err.response)
      } else if (err.request) {
        this.errorMessage = t("no_server_response")
      } else {
        this.errorMessage = err.message
        console.error(err)
      }

      this.submitting = false
      this.view = "error"
    },

    removeBoatInquiry() {
      this.$set(this.inquiry.boat_inquiry, "_destroy", true)
    },

    addBoatInquiry() {
      if (this.inquiry.boat_inquiry) {
        this.$set(this.inquiry.boat_inquiry, "_destroy", null)
      } else {
        this.$set(this.inquiry, "boat_inquiry", {
          ...boat_inquiry,
          inquiry_id: this.inquiry.id,
        })
      }
    },

    _updateDataFromRemote(inquiry) {
      if (inquiry) {
        this.inquiry = inquiry
        this.trackingChanges.track(inquiry) // see ./TrackingChanges.js
        window.sidebarDetails.setInquiry(inquiry)
        this.skipNotification = false
      }

      const { energy_cost_calculation: ecc } = this.villa || {}
      if (ecc && this.canChangeInquiryECC()) {
        // update inquiry, unless inquiry is legacy or has overriden value
        this.inquiry.villa_inquiry.energy_cost_calculation = ecc
      }

      setTimeout(() => {
        this.submitting = false
      }, 500)
    },

    requestClearing() {
      this.$nextTick(() => {
        if (this.mayRequestClearing) {
          this.$refs.priceTable.requestClearing()
        }
      })
    },

    buildCommonClearingParams() {
      const params = {
        inquiry_id: this.inquiry.id,
        external:   this.inquiry.external,
        currency:   this.inquiry.currency,
        villa:      {
          villa_id: this.inquiry.villa_inquiry.villa_id,
        },
      }

      if (this.inquiry.boat_inquiry && this.inquiry.boat_inquiry.boat_id) {
        params.boat = {
          boat_id:    this.inquiry.boat_inquiry.boat_id,
          start_date: this.inquiry.boat_inquiry.start_date,
          end_date:   this.inquiry.boat_inquiry.end_date,
          inclusive:  this.inquiry.boat_inquiry.inclusive,
        }
      }
      return params
    },

    canChangeInquiryECC() {
      const { energy_cost_calculation: ecc } = this.inquiry.villa_inquiry
      return !ecc || !(ecc.startsWith("override_") || ecc === "legacy")
    },
  },

  async mounted() {
    const url = `/api/admin/inquiries/villas/${this.inquiryId || "new"}.json`

    try {
      const [data] = await Promise.all([
        Utils.fetchJSON(url),
        awaitSpecialDates(),
      ])

      this.villas = data.villas
      this._updateDataFromRemote(data.inquiry)
      Inconsistencies.display(data.inconsistencies)
      this.view = this.inquiryId ? "edit" : "new"
      this.requestClearing()
    } catch (err) {
      this._handleErrorFromRemote(err)
    }
  },
}
