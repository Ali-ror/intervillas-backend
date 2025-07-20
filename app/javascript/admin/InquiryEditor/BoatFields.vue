<template>
  <div class="form-group">
    <div v-if="value.inclusive" class="col-md-12">
      <UiAlert variant="warning" class="mt-4">
        {{ value.name }}<br>
        {{ t("boat.inclusive") }}
      </UiAlert>
    </div>

    <template v-else>
      <div class="col-md-6">
        <ErrorWrapper :errors="validations.boat_id">
          <label for="boat-id" v-text="t('boat.label')" />
          <UiSelect
              id="boat-id"
              v-model="boat_id"
              :placeholder="translate('generic.please_select')"
              :disabled="disabled"
              :options="boatOptionsForSelect"
              label="name"
              :selectable="opt => !opt.header"
              :reduce="opt => opt.id"
              :template="BoatFieldOption"
          />
        </ErrorWrapper>
      </div>
      <div class="col-md-6">
        <label for="boat-range" v-text="t('range')" />
        <ErrorWrapper :errors="validations.start_date">
          <BoatRangePicker
              id="boat-range"
              :start-date="start_date"
              :end-date="end_date"
              :available="boat && boat.free"
              @change="onRangeChange"
          />
        </ErrorWrapper>
      </div>

      <div class="col-md-12">
        <button
            class="btn btn-danger mt-2"
            type="button"
            @click="removeBoat()"
            v-text="t('boat.remove')"
        />
      </div>

      <div class="col-md-12">
        <div
            v-if="msg"
            id="boat-selector-alert"
            :class="`alert alert-${alert}`"
            v-text="msg"
        />
      </div>
    </template>
  </div>
</template>

<script>
import Utils from "../../intervillas-drp/utils"
import { groupBy } from "lodash"
import BoatRangePicker from "./BoatRangePicker.vue"
import ErrorWrapper from "./ErrorWrapper.vue"
import BoatFieldOption from "./BoatFieldOption.vue"
import UiAlert from "../../components/UiAlert.vue"
import UiSelect from "../../components/UiSelect.vue"

import { translate } from "@digineo/vue-translate"
import { differenceInDays, format } from "date-fns"
const t = key => translate(key, { scope: "inquiry_editor.inquiry" })

const MIN_BOAT_DAYS = 1

export default {
  name: "BoatFields",

  components: {
    BoatRangePicker,
    ErrorWrapper,
    UiAlert,
    UiSelect,
  },

  props: {
    value:       { type: Object, required: true },
    validations: { type: Object, required: true },
  },

  setup() {
    return {
      BoatFieldOption,
    }
  },

  data() {
    return {
      disabled:             false,
      alert:                "info",
      msg:                  t("remote_data.loading"),
      boatOptionsForSelect: [],
      boat:                 {},
      occupancies:          [],
      dropdownOpen:         false,

      bi: {
        boat_id:    this.value.boat_id,
        start_date: this.value.start_date,
        end_date:   this.value.end_date,
        inquiry_id: this.value.inquiry_id,
        name:       this.value.name,
        days:       this.value.days,
        discounts:  this.value.discounts,
      },
    }
  },

  computed: {
    boat_id: {
      get() {
        return this.value.boat_id
      },
      set(boat_id) {
        const [id, boat] = (() => {
          if (boat_id == null) {
            return []
          }

          const id = parseInt(boat_id, 10),
                boat = this.occupancies.find(boat => boat.id === id)
          return [id, boat]
        })()

        if (boat) {
          this.boat = boat
          this.bi.boat_id = id
          this.bi.name = this.boat.name
        } else {
          this.boat = {}
          this.bi.boat_id = null
          this.bi.name = null
        }

        this.emitChanges()
        this.validations.$reset()
      },
    },

    start_date: {
      get() {
        return this.value.start_date
      },
      set(start_date) {
        this.bi.start_date = start_date
        this.emitChanges()
      },
    },

    end_date: {
      get() {
        return this.value.end_date
      },
      set(end_date) {
        this.bi.end_date = end_date
        this.emitChanges()
      },
    },
  },

  async mounted() {
    try {
      const { boats } = await Utils.fetchJSON(`/api/admin/boat_occupancies/${this.bi.inquiry_id}`)
      this.disableForm(false)
      this.occupancies = boats
      this.initBoatPicker()
    } catch (err) {
      console.log(err)
      this.disableForm("danger", t("remote_data.load_error"))
    }
  },

  methods: {
    translate,
    t,

    hideDropdown() {
      this.dropdownOpen = false
    },

    removeBoat() {
      this.$emit("remove", this.bi)
    },

    disableForm(alert, msg) {
      this.alert = alert
      this.msg = msg
      this.disabled = !!alert
    },

    onRangeChange([start, end]) {
      this.deferEmits(() => {
        this.bi.days = differenceInDays(end, start) + 1
        this.start_date = format(start, "yyyy-MM-dd")
        this.end_date = format(end, "yyyy-MM-dd")
      })
    },

    deferEmits(work) {
      this._deferChangeEmission = true
      work()
      this._deferChangeEmission = false
      this.emitChanges()
    },

    emitChanges() {
      if (this._deferChangeEmission) {
        return
      }

      this.$emit("input", this.bi)
      this.$emit("changed:price-relevant")
    },

    initBoatPicker() {
      // Boote nach group gruppieren und selektiertes Boot merken
      this.boat = this.occupancies.find(boat => boat.selected)

      // Boote deaktivieren, die:
      // - nicht genügend freie Tage vorweisen können
      // - bereits gebucht sind
      this.occupancies.forEach(boat => {
        boat.disabled = (boat.id !== this.boat_id && boat.free.length < MIN_BOAT_DAYS)
        || boat.group === "hidden"
      })

      // Daten für ui-select zusammenstellen
      const groups = groupBy(this.occupancies, boat => boat.group),
            groupLabels = ["optional", "others", "inclusive", "hidden"]

      this.boatOptionsForSelect = groupLabels.reduce((collection, g) => {
        const children = groups[g]
        if (children) {
          collection.push({ name: t(`boat.groups.${g}`), header: true })
          collection.push(...children)
        }
        return collection
      }, [])
    },
  },
}
</script>

<style scoped>
  .input-group-addon {
    cursor: pointer;
  }
</style>
