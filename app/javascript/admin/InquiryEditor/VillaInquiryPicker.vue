<template>
  <div v-if="state === 'init'">
    <p
        class="form-control-static text-muted"
        v-text="t('inquiry.villa.villa_missing')"
    />
  </div>

  <div v-else-if="state === 'loading'">
    <p
        class="form-control-static text-muted"
        v-text="t('inquiry.remote_data.loading')"
    />
  </div>

  <div v-else-if="state === 'error'">
    <p class="form-control-static text-danger">
      <button
          type="button"
          class="pull-right btn btn-xxs btn-default"
          @click="reloadData"
      >
        <i class="fa fa-refresh" />
      </button>
      {{ t("inquiry.remote_data.load") }}
    </p>
  </div>

  <RangePicker
      v-else
      ref="rangePicker"
      :start-date="start"
      :end-date="end"
      :start-date-input-name="false"
      :end-date-input-name="false"
      :unavailable="unavailable"
      :annotate="annotate"
      :captions="captions"
      :can-delete="false"
      split-days
      @change="onChange"
      @delete="onChange([])"
  >
    <template #display="display">
      <div
          v-if="display.start && display.end"
          class="input-group"
          :class="{ 'input-group-sm': size === 'sm' }"
      >
        <span class="form-control">{{ formatDate(display.start) }}</span>
        <span
            class="input-group-addon"
            style="border-width:1px 0"
        >–</span>
        <span class="form-control">{{ formatDate(display.end) }}</span>
        <span class="input-group-addon"><i class="fa fa-calendar" /></span>
      </div>
      <div
          v-else
          class="input-group"
          :class="{ 'input-group-sm': size === 'sm' }"
      >
        <span class="form-control">
          <span class="text-muted">{{ translate("drp.label.please_select") }}</span>
        </span>
        <span class="input-group-addon"><i class="fa fa-calendar" /></span>
      </div>
    </template>
  </RangePicker>
</template>

<script>
import { RangePicker, Caption } from "@digineo/date-range-picker"
import Utils from "../../intervillas-drp/utils"
import SpecialDates from "../../intervillas-drp/special-dates"
import { translate } from "@digineo/vue-translate"
import { makeDate, formatDate } from "../../lib/DateFormatter"
import { parseISO, isSameDay, setHours } from "date-fns"

const intMaybe = num => !num || !isNaN(parseInt(num, 10))

export default {
  components: {
    RangePicker,
  },

  props: {
    inquiryId: { type: [String, Number], default: null, validator: intMaybe },
    villaId:   { type: [String, Number], default: null, validator: intMaybe },
    startDate: { type: [String, Date, Number], default: null },
    endDate:   { type: [String, Date, Number], default: null },

    size: { type: String, default: null, validator: v => !v || v === "sm" },
  },

  data() {
    return {
      state:       "init",
      unavailable: [],
      start:       this.startDate ? makeDate(this.startDate) : null,
      end:         this.endDate ? makeDate(this.endDate) : null,
      captions:    [
        new Caption("high-season", "drp.caption.high_season"),
        new Caption("today", "drp.caption.today"),
      ],
    }
  },

  watch: {
    villaId(id, oldId) {
      if (id && id !== oldId) {
        this.reloadData().then(() => {
          this._alertIfAlreadyOccupied()
        })
      } else {
        this.state = "init"
        this.start = null
        this.end = null
      }
    },

    startDate(date) {
      this.start = date ? setHours(makeDate(date), 16) : null
    },

    endDate(date) {
      this.end = date ? setHours(makeDate(date), 8) : null
    },
  },

  mounted() {
    if (this.state === "init" && this.villaId) {
      this.reloadData()
    }
  },

  methods: {
    formatDate,
    translate,
    t: key => translate(key, { scope: "inquiry_editor" }),

    annotate(date) {
      const seasons = SpecialDates.highSeason.get(date.getFullYear(), this.villaId),
            annos = {
              "high-seasons": false,
              "today":        isSameDay(date, new Date()),
            }

      for (let i = 0, len = seasons.length; i < len; ++i) {
        if (seasons[i].contains(date)) {
          annos["high-season"] = true
          break
        }
      }
      return annos
    },

    /**
     * Benutzer hat eine Auswahl getroffen.
     */
    onChange([start, end]) {
      this.start = start
      this.end = end
      this.$emit("change")
      this.$emit("update:startDate", start)
      this.$emit("update:endDate", end)
    },

    /**
     * Holt die belegten Datumsbereiche vom Server ab
     */
    async reloadData() {
      if (!this.villaId || this.villaId === "") {
        this.state = "error"
        return
      }

      this.state = "loading"
      this.unavailable.splice(0)

      const url = this.inquiryId
        ? `/api/admin/occupancies/villas/${this.villaId}.json?except=${this.inquiryId}`
        : `/api/admin/occupancies/villas/${this.villaId}.json`

      try {
        const data = await Utils.fetchJSON(url)

        // We need to "shrink/shift" date ranges: parseISO sets hours to 0, which
        // will cause the half-day-blocking in the DateRangePicker to misbehave.
        // The arrival time must be > 12pm, and the departure time < 12pm. Using
        // 4pm and 8am respectively coincidentally matches reality, but 12:01pm and
        // 11:59am would work as well.
        this.unavailable.push(...data.map(([a, b]) => ([
          setHours(parseISO(a), 16),
          setHours(parseISO(b), 8),
        ])))

        this.$emit("reload:unavailable", this.unavailable)
        this.state = "loaded"
      } catch (_err) {
        this.state = "error"
      }
    },

    /**
     * Wenn die Villa-ID geändert wird (siehe villaId-Watcher), dann kann
     * ein bereits ausgewähltes Datum ungültig werden (alte Villa war frei
     * neue Villa ist es nicht mehr).
     *
     * Dies prüft, ob es eine Überschneidung mit den blockierten Daten gibt,
     * und propagiert den Zustand in die Parent-Komponente.
     *
     * @todo: Der Zugriff auf $ref ist ein Smell. Besser wäre es vermutlich,
     * RangePicker#collection (bzw. SinglePicker#collection) nicht als
     * Computed Property zu haben, sondern die blockierten Daten als Prop
     * hineinzugeben.
     */
    _alertIfAlreadyOccupied() {
      if (this.isOccupied()) {
        this.$emit("alert:occupied")
      }
    },

    isOccupied() {
      if (!this.start || !this.end) {
        return
      }

      const rp = this.$refs.rangePicker
      if (!rp || !rp.collection) {
        return
      }
      for (let day of rp.collection.sliceDays(this.start, this.end)) {
        if (day.options.blocked) {
          return true
        }
      }
      return false
    },
  },
}
</script>
