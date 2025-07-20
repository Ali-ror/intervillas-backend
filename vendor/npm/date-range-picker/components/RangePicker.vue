<template>
  <div v-outside-click="cancelAndHide" class="date-range-picker-wrapper">
    <div class="display" @click="toggle">
      <input
          v-for="input of inputs" :key="input.name"
          type="hidden"
          :name="input.name"
          :value="input.value"
      >
      <slot
          name="display"
          :start="start"
          :end="end"
      />
    </div>
    <div
        v-if="isOpen || inline"
        class="panel panel-default date-range-picker"
        :class="{
          'date-range-picker-single': singleCalendar || inline,
          inline,
        }"
    >
      <div v-if="!inline" class="arrow" />
      <div class="panel-body">
        <div class="row">
          <DrpCalendar
              v-for="(cal, i) of calendars" :key="i"
              v-bind="cal"
              @select="onSelect"
              @hover="onHoverDay"
              @change="onCalendarChange"
              @cancel="onCancelAndSelect"
          ></DrpCalendar>
        </div>
        <div v-if="singleCalendar || inline" class="text-muted date-range-picker-caption">
          <!-- eslint-disable vue/no-v-html -->
          <p
              v-for="m of messages"
              :key="m.id"
              class="small"
              :class="`message-${m.id}`"
              v-html="m.toString()"
          />
          <!-- eslint-enable vue/no-v-html -->
          <table class="table small">
            <tr v-for="(caption, i) of activeCaptions" :key="i">
              <td
                  class="date within"
                  :class="caption.className"
                  v-text="'#'"
              />
              <td v-text="caption.toString()" />
            </tr>
          </table>
        </div>

        <div v-else class="row text-muted date-range-picker-caption">
          <div :class="messages.length > 0 ? 'col-xs-6' : 'col-xs-12'">
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

          <div v-if="messages.length > 0" class="col-xs-6">
            <!-- eslint-disable vue/no-v-html -->
            <p
                v-for="m of messages"
                :key="m.id"
                :class="`message-${m.id}`"
                v-html="m.toString()"
            />
            <!-- eslint-enable vue/no-v-html -->
          </div>
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
import SinglePicker from "./SinglePicker.vue"
import Message from "../message"
import { translate } from "@digineo/vue-translate"
import { DateRange } from "../DateRange"

export default {
  name: "RangePicker",

  extends: SinglePicker,

  props: {
    endDate:            { type: [Date, Number], default: null },
    endDateInputName:   { type: [Boolean, String], default: "end" },
    endDateInputFormat: { type: String, default: "yyyy-MM-dd" },

    rangeSize: { type: Function, default: () => 0 },
    rangeType: { type: String, default: "nights", validator: (val) => ["days", "nights"].includes(val) },
  },

  data() {
    const selected = this.startDate && this.endDate
      ? [this.startDate, this.endDate].map(d => ensureDate(d))
      : null

    return {
      selected,
      isSingle:       false,
      lastHoveredDay: null,
    }
  },

  computed: {
    end() {
      return !this.single && this.selected && ensureDate(this.selected[1])
    },

    inSelectMode() {
      return !!this.activeSelection
    },

    inputs() {
      const i = []
      if (this.startDateInputName !== false) {
        i.push(new DateInput(this.startDateInputName, this.startDateInputFormat, this.start))
      }
      if (this.endDateInputName !== false) {
        i.push(new DateInput(this.endDateInputName, this.endDateInputFormat, this.end))
      }
      return i
    },

    calendars() {
      // TODO: dies müsste relativ einfach auf 12 Monatskalender zu erweitern sein
      let calendars = []
      if (this.singleCalendar || this.inline) {
        calendars = ["both"]
      } else {
        calendars = ["left", "right"]
      }

      this.currentCaptions = {} // eslint-disable-line vue/no-side-effects-in-computed-properties
      return calendars.map((pos, i) => this._buildCalendar(pos, i))
    },

    messages() {
      const messages = []
      if (this.dateSelection.lastResult) {
        const r = this.dateSelection.lastResult
        if (r.finished) {
          messages.push(Message.fromResult("fill-in", r))
        } else if (r.min > 0) {
          r.typeKey = this.rangeType
          if (this.rangeType === "days") {
            r.type = translate("drp.range_type.days")
          } else {
            r.type = translate("drp.range_type.nights")
          }

          messages.push(Message.fromResult("min-range", r))
        }
      }
      return messages
    },
  },

  watch: {
    startDate(newVal) {
      if (newVal && this.endDate) {
        this._doSelect({
          start: ensureDate(newVal),
          end:   ensureDate(this.endDate),
        })
      }
    },

    endDate(newVal) {
      if (this.startDate && newVal) {
        this._doSelect({
          start: ensureDate(this.startDate),
          end:   ensureDate(newVal),
        })
      }
    },
  },

  methods: {
    /**
     * Liefert im Auswahl-Modus den (korrigierte) Auswahl-Vorschlag, und,
     * sofern der User Start- und Enddatum ausgewählt hat, diese Auswahl.
     *
     * Wenn beides nicht zutrifft (nicht im Auswahl-Modus, Start- oder
     * End-Datum nicht gegeben) ist das Ergbenis undefiniert.
     *
     * @returns {DateRange | undefined}
     */
    _currentSelection() {
      if (this.inSelectMode && this.lastHoveredDay) {
        return this._adjustedSelection().range
      } else if (this.selected) {
        return new DateRange(...this.selected)
      }
    },

    /**
     * Justiert die aktuelle Auswahl (this.activeSelection) und das Datum
     * unter der Maus (this.lastHoveredDay) so, dass:
     *
     * - mindestens this.rangeSize Tage abgedeckt werden
     * - aber maximal der zur Verfügung stehende Platz genutzt wird
     *
     * @private
     * @return {DateSelection.Result}
     */
    _adjustedSelection() {
      // "physikalische" Auswahl des Users
      const curr = this.activeSelection,
            mouse = this.lastHoveredDay
      return this.dateSelection.select(curr, mouse)
    },

    _canSelect(day) {
      return this.inSelectMode
        ? this.activeSelection.matches(day)
        : true
    },

    /**
     * User hat auf OK-Button geklickt.
     */
    onOKClick() {
      this._maybeFinishSelection(this.lastHoveredDay)

      // invalid if in select mode (i.e. no start or end date)
      if (this.inSelectMode || !this.selected) {
        return
      }

      this._emitChange()
      this.hide()
    },

    /**
     * Event-Handler für Klick auf ein Datum.
     * @param {Day} day Datum, auf das der User geklickt hat.
     */
    onSelect(day) {
      this.inSelectMode
        ? this._maybeFinishSelection(day)
        : this._startSelection(day)
    },

    /** @private Merkt sich den ausgewählten Tag als "aktuelle Auswahl" */
    _startSelection(day) {
      this.activeSelection = day
      const adjusted = this._adjustedSelection()
      if (adjusted.finished) {
        this._doSelect(adjusted.range)
      }
    },

    /** @private Beendet die "aktuelle Auswahl" */
    _maybeFinishSelection(day) {
      if (this.inSelectMode && this.activeSelection.matches(day)) {
        // valid selection: both dates must are free and in the same group
        this._doSelect(this._adjustedSelection().range)
      }
    },

    /** @private Beendet Auswahl-Modus und übernimmt Start-/End-Datum ohne weitere Prüfung */
    _doSelect({ start, end }) {
      this.selected = [makeDate(start), makeDate(end)]
      this.activeSelection = null
      if (this.inline) {
        this._emitChange()
      }
    },

    /** Merkt sich den zuletzt mit der Maus überfahrenen Day */
    onHoverDay(day) {
      this.lastHoveredDay = day
    },

    /**
     * User hat auf Cancel geklickt.
     */
    onCancelClick() {
      this.inSelectMode
        ? this._cancelSelection()
        : this._deleteSelection()
    },

    onCancelAndSelect(day) {
      this.activeSelection = null
      this.lastHoveredDay = day
      this.onSelect(day)
    },

    /**
     * Hebt aktuelle Auswahl auf, und stellt vorherige Auswahl wieder her (sofern vorhanden).
     * @private
     */
    _cancelSelection() {
      this.activeSelection = null
    },

    /**
     * Entfernt aktuelle Auswahl.
     * @private
     */
    _deleteSelection() {
      if (this.canDelete) {
        this.selected = null
        this.activeSelection = null
        this.$emit("delete")
      }

      this.toggle()
    },
  },
}
</script>
