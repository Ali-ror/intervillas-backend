<template>
  <FormGroup
      :model="highSeason"
      field="starts_on"
      label="Zeitraum"
      type="slot"
  >
    <RangePicker
        :start-date="highSeason.starts_on"
        :end-date="highSeason.ends_on"
        start-date-input-name="high_season[starts_on]"
        end-date-input-name="high_season[ends_on]"
    >
      <template #display="display">
        <div v-if="display.start && display.end" class="input-group">
          <span class="form-control">{{ formatDate(display.start) }}</span>
          <span class="input-group-addon" style="border-width:1px 0"> – </span>
          <span class="form-control">{{ formatDate(display.end) }}</span>
          <span class="input-group-addon"><i class="fa fa-calendar" /></span>
        </div>
        <div v-else class="input-group">
          <span class="form-control">
            <span class="text-muted">{{ "drp.label.please_select" | translate }}</span>
          </span>
          <span class="input-group-addon"><i class="fa fa-calendar" /></span>
        </div>
      </template>
    </RangePicker>
  </FormGroup>
</template>

<script>
import { RangePicker } from "@digineo/date-range-picker"
import { makeDate, formatDate } from "../lib/DateFormatter"
import FormGroup from "./FormGroup.vue"
import Model from "./models/model"

const Schema = Model.create({
  starts_on: {
    label:    "Anfang",
    presence: true,
    date:     true,
  },
  ends_on: {
    label:    "Ende",
    presence: true,
    date:     true,
  },
})

class HighSeason extends Schema {
  // Nothing to see here
}

export default {
  components: {
    FormGroup,
    RangePicker,
  },

  props: {
    startDate: { type: String, default: null },
    endDate:   { type: String, default: null },
  },

  data() {
    const highSeason = new HighSeason()
    if (this.startDate && this.endDate) {
      highSeason.update({
        starts_on: makeDate(this.startDate),
        ends_on:   makeDate(this.endDate),
      })
      highSeason.clean()
    }
    return {
      highSeason,
    }
  },

  mounted() {
    this.highSeason.clean()
  },

  methods: {
    formatDate,
  },
}
</script>
