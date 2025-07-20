<template>
  <div v-outside-click="cancelAndHide" class="date-range-picker-wrapper">
    <div class="display" @click="toggle">
      <input
          v-for="input of inputs" :key="input.name"
          type="hidden"
          :name="input.name"
          :value="input.value"
      >
      <slot name="display" :start="start" />
    </div>

    <div v-if="isOpen" class="panel panel-default date-range-picker date-range-picker-single">
      <div class="arrow" />
      <div class="panel-body">
        <div class="row">
          <DrpCalendar
              v-for="(cal, i) of calendars" :key="i"
              v-bind="cal"
              @select="onSelect"
              @change="onCalendarChange"
              @cancel="onCancelAndSelect"
          ></DrpCalendar>
        </div>
        <div class="text-muted date-range-picker-caption">
          <!-- eslint-disable vue/no-v-html -->
          <p
              v-for="m of messages"
              :key="m.id"
              :class="`message-${m.id}`"
              v-html="m.toString()"
          />
          <!-- eslint-enable vue/no-v-html -->
          <table class="table small">
            <tr v-for="(caption, i) of activeCaptions" :key="i">
              <td
                  class="date"
                  :class="caption.className"
                  v-text="'#'"
              />
              <td v-text="caption.toString()" />
            </tr>
          </table>
        </div>
      </div>
      <div v-if="!inline" class="panel-footer text-right">
        <button
            class="btn btn-default btn-sm"
            type="button"
            @click="onCancelClick"
        >
          <i :class="icon('btnCancel')" />
          {{ "drp.btn.cancel" | translate }}
        </button>
        <button
            class="btn btn-primary btn-sm"
            type="button"
            @click="onOKClick"
        >
          <i :class="icon('btnOK')" />
          {{ "drp.btn.ok" | translate }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ensureDate, DateInput, makeDate } from "../utils"
import { getIcon } from "../configuration"
import DynamicSize from "./DynamicSize"
import DrpCalendar from "./DrpCalendar.vue"
import Collection from "../pickable/collection"
import DateSelection from "../date-selection"
import Caption from "../caption"
import {
  addMonths,
  startOfDay, endOfDay,
  isAfter, isBefore,
  isSameDay, isSameMonth,
  setDate, getDate, getDaysInMonth,
} from "date-fns"
import { DateRange } from "../DateRange"

export default {
  name: "SinglePicker",

  components: {
    DrpCalendar,
  },

  mixins: [DynamicSize],

  props: {
    startDate:            undefined,
    startDateInputName:   { type: [Boolean, String], default: "start" },
    startDateInputFormat: { type: String, default: "yyyy-MM-dd" },

    inline:      { type: Boolean, default: false },
    splitDays:   { type: Boolean, default: false },
    minDate:     { type: [Date, Number], default: null },
    maxDate:     { type: [Date, Number], default: null },
    selectMax:   { type: [Date, Number], default: null },
    keepDay:     { type: Boolean, default: false },
    canDelete:   { type: Boolean, default: true },
    unavailable: { type: Array, default: () => [] },
    annotate:    { type: Function, default: () => ({}) },
    open:        { type: Boolean, default: false },
    captions:    { type: Array, default: () => [] },
  },

  data() {
    const selected = this.startDate && [ensureDate(this.startDate)]

    const calendarMonth = selected
      ? ensureDate(selected[0])
      : this.minDate
        ? ensureDate(this.minDate, false)
        : undefined

    return {
      selected,
      calendarMonth,
      activeSelection: null, // aktive Auswahl
      dateSelection:   new DateSelection(this.rangeSize),

      isOpen:   this.open || false,
      isSingle: true,

      captionList: [
        new Caption("blocked", "drp.state.blocked"),
        new Caption("selected", "drp.state.selected"),
        ...Caption.from(this.captions),
      ],
      currentCaptions: {},
    }
  },

  computed: {
    start() {
      return this.selected && ensureDate(this.selected[0])
    },

    min() {
      return this.minDate && ensureDate(this.minDate, false)
    },

    max() {
      return this.maxDate && ensureDate(this.maxDate, false)
    },

    collection() {
      return new Collection(this.unavailable, this.min, this.max)
    },

    inputs() {
      if (this.startDateInputName !== false) {
        return [new DateInput(this.startDateInputName, this.startDateInputFormat, this.start)]
      }
      return []
    },

    calendars() {
      this.currentCaptions = {} // eslint-disable-line vue/no-side-effects-in-computed-properties
      return [this._buildCalendar("both", 0)]
    },

    messages() {
      return []
    },

    inSelectMode() {
      return false
    },

    activeCaptions() {
      return this.captionList.filter(caption => this.currentCaptions[caption.className])
    },
  },

  mounted() {
    if (this.inline) {
      this.show()
    }
  },

  methods: {
    icon(name) {
      return getIcon(name)
    },

    /** Öffnet oder schließt das Widget. */
    toggle() {
      this.isOpen ? this.hide() : this.show()
    },

    hide() {
      this.isOpen = false

      // Anzeige-Monat zurücksetzen
      const selected = this.startDate && [ensureDate(this.startDate)]
      this.calendarMonth = selected
        ? selected[0]
        : this.minDate
          ? ensureDate(this.minDate, false)
          : undefined
    },

    show() {
      this.isOpen = true

      // Sicherstellen, dass Widget nicht aus Fenster herausragt
      this.hOffset = 0
      this.move()
    },

    /** @private Merkt sich den ausgewählten Tag als "aktuelle Auswahl" */
    _maybeFinishSelection(day) {
      // stub
    },

    /** @private notify listeners */
    _emitChange() {
      this.$emit("change", this.selected || [])
    },

    /**
     * Generiert notwendige Daten für die Calendar.vue-Komponente.
     *
     * @private
     * @param {"left" | "right" | "both" | "none"} ctrlPos Anordnung der Blätter-Controls
     * @param {number} offset Angezeigter Monat = this.calendarMonth + offset Monate
     * @returns {object}
     */
    _buildCalendar(ctrlPos, offset) {
      const candidate = this.calendarMonth || (this.selected && this.selected[0]) || this.min || new Date(),
            date = addMonths(makeDate(candidate), offset)

      return {
        controls:  ctrlPos,
        date:      date,
        min:       this.min,
        max:       this.max,
        days:      this._annotatedDays(date),
        selectMax: this.selectMax,
        inline:    this.inline,
        splitDays: this.splitDays,
      }
    },

    /**
     * Generiert eine Liste annotierter Daten für einen Kalender-Monat.
     *
     * Impl.-Detail: Die Annotationen bestehen letztendlich aus CSS-Klassen-Namen
     * für die gerenderte Tabellenzelle.
     *
     * @private
     * @param {number | Date} month
     * @returns {Day[]}
     */
    _annotatedDays(month) {
      const sel = this._currentSelection()

      return this.collection.sliceCalendarMonth(month, !this.inline).map(day => {
        const curr = day.date,
              otherMonth = !isSameMonth(curr, month),
              { am, pm } = day.blockedHalfs

        const classes = {
          "other-month": otherMonth,
          "blocked":     !otherMonth && (day.blocked || !this._canSelect(day)),
          "free":        !otherMonth && day.free,
        }

        if (this.splitDays) {
          classes["blocked-am"] = !otherMonth && am
          classes["blocked-pm"] = !otherMonth && pm
        }
        if (sel && !otherMonth) {
          const type = this.inSelectMode ? "preselected" : "selected"
          classes[type] = sel.contains(curr)
          classes["start"] = isSameDay(sel.start, curr)
          classes["end"] = isSameDay(sel.end, curr)
          classes["within"] = isBefore(sel.start, curr) && !isSameDay(sel.start, curr) && isAfter(sel.end, curr)
        }

        Object.entries(this.annotate(curr) || {}).forEach(([annotation, value]) => {
          classes[annotation] = value
        })

        Object.keys(classes).forEach(c => {
          this.currentCaptions[c] = classes[c] || this.currentCaptions[c]
        })

        day.annotations = classes
        return day
      })
    },

    _currentSelection() {
      if (this.selected) {
        return new DateRange(
          startOfDay(this.selected[0]),
          endOfDay(this.selected[0]),
        )
      }
    },

    _canSelect(day) {
      return true
    },

    /**
     * User hat Ansicht im Kalender gewechselt. Das Datum muss, sofern konfiguriert, zwischen den
     * min/max-Grenzen liegen (this.min und this.max). Daten < min werden auf min gelegt (und vice
     * versa Daten > max).
     * @param {number | Date} date Das neue Anzeige-Datum
     */
    onCalendarChange(date) {
      if (this.min && isBefore(date, this.min)) {
        this.calendarMonth = this.min
        return
      }
      if (this.max && isAfter(date, this.max)) {
        this.calendarMonth = this.max
        return
      }

      this.calendarMonth = date

      if (this.keepDay && this.selected) {
        const tmp = makeDate(this.calendarMonth),
              day = Math.min(getDate(this.selected[0]), getDaysInMonth(tmp))
        this.selected = [setDate(tmp, day)]
      }
    },

    /**
     * User hat auf OK-Button geklickt.
     */
    onOKClick() {
      this._maybeFinishSelection()
      this._emitChange()
      this.hide()
    },

    /**
     * Event-Handler für Klick auf ein Datum.
     * @param {Day} day Datum, auf das der User geklickt hat.
     */
    onSelect(day) {
      this.selected = [day.date]
      this.activeSelection = null
    },

    /**
     * User hat auf Cancel geklickt.
     */
    onCancelClick() {
      if (this.canDelete) {
        this.selected = null
        this.activeSelection = null
        this.$emit("delete")
      }

      this.hide()
    },

    onCancelAndSelect(day) {
      this.activeSelection = null
      this.onSelect(day)
    },

    cancelAndHide() {
      if (!this.inline) {
        this.activeSelection = null
        this.hide()
      }
    },
  },
}
</script>
