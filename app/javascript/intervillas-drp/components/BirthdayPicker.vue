<template>
  <div>
    <SinglePicker
        :start-date-input-name="name"
        :start-date="value"
        :can-delete="!preventDelete"
        :keep-day="true"
        :select-max="maxDate"
        @change="selected = $event[0]"
    >
      <template #display="display">
        <span v-if="small && display.start" class="form-control input-sm">
          {{ formatDate(display.start) }}
        </span>
        <div v-else-if="small && !display.start" class="form-control input-sm">
          <span class="text-muted">
            {{ translate("drp.label.please_select") }}
          </span>
        </div>

        <div v-else class="input-group">
          <span v-if="display.start" class="form-control">
            {{ formatDate(display.start) }}
          </span>
          <span v-else class="form-control">
            <span class="text-muted">
              {{ translate("drp.label.please_select") }}
            </span>
          </span>
          <span class="input-group-addon">
            <i class="fa fa-calendar" />
          </span>
        </div>
      </template>
    </SinglePicker>

    <span v-if="congratulate" class="help-block">
      <i class="fa fa-fw fa-birthday-cake" />
      Happy Birthday!
      <i class="fa fa-fw fa-heart" />
    </span>
  </div>
</template>

<script>
import { SinglePicker } from "@digineo/date-range-picker"
import { translate } from "@digineo/vue-translate"
import { endOfDay, isBefore, startOfDay } from "date-fns"
import { makeDate, formatDate } from "../../lib/DateFormatter"

export default {
  name: "BirthdayPicker",

  components: {
    SinglePicker,
  },

  props: {
    name:          { type: String, required: true }, // name of input field
    value:         { type: [String, Date, Number], default: null }, // not actually v-model (we don't emit changes here)
    small:         { type: Boolean, default: false },
    preventDelete: { type: Boolean, default: false },
    birthday:      { type: Array, default: null }, // travel dates, to highligh birthday
  },

  data() {
    return {
      selected: null,
      maxDate:  new Date(),
    }
  },

  computed: {
    highlightBirthday() {
      if (!this.birthday) {
        return
      }

      const [s, e] = this.birthday
      return [
        startOfDay(makeDate(s)),
        endOfDay(makeDate(e)),
      ]
    },

    congratulate() {
      if (this.highlightBirthday && this.selected) {
        const [s, e] = this.highlightBirthday,
              dob = new Date(this.selected)

        dob.setHours(12, 0, 0, 0)
        if (dob.getMonth() === 1 && dob.getDate() === 29) {
          // hack: born on Feb 29
          dob.setFullYear(s.getFullYear(), 2, 1)
        } else {
          dob.setFullYear(s.getFullYear(), dob.getMonth(), dob.getDate())
        }
        // startOfDay(s) < midday(dob) < endOfDay(e)
        return isBefore(s, dob) && isBefore(dob, e)
      }
      return false
    },
  },

  methods: {
    formatDate,
    translate,
  },
}
</script>
