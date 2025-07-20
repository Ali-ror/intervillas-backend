<template>
  <SinglePicker
      :start-date-input-name="name"
      :start-date="value"
      :can-delete="false"
  >
    <template #display="{ start }">
      <div class="input-group">
        <span v-if="start" class="form-control">
          {{ formatDate(start) }}
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
</template>

<script>
import { SinglePicker } from "@digineo/date-range-picker"
import { translate } from "@digineo/vue-translate"
import { formatDate } from "../../lib/DateFormatter"

export default {
  components: {
    SinglePicker,
  },

  props: {
    name:  { type: String, required: true },
    value: { type: [String, Date], default: () => new Date() },
  },

  data() {
    return {
      preventDelete: false,
    }
  },

  methods: {
    translate,
    formatDate,
  },
}
</script>
