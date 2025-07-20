<template>
  <div>
    <div class="form-group">
      <span class="form-label">
        <label for="customer_country" class="control_label">
          {{ t("country") }}<abbr title="Pflichtfeld">*</abbr>
        </label>
      </span>

      <span class="form-wrapper" v-if="!customer.country || customer.country in countries">
        <select
            v-model="customer.country"
            id="customer_country"
            name="customer[country]"
            class="form-control"
            required
        >
          <option
              v-for="c in CountryCodeOptions.prio"
              :key="c.code"
              :value="c.code"
              v-text="c.name"
          />
          <option v-if="CountryCodeOptions.prio.length" disabled>----------</option>
          <option
              v-for="c in CountryCodeOptions.rest"
              :key="c.code"
              :value="c.code"
              v-text="c.name"
          />
        </select>
      </span>
      <span class="form-wrapper" v-else>
        <input
            v-model="customer.country"
            id="customer_country"
            name="customer[country]"
            class="form-control"
            required
        >
      </span>
    </div>
    <div class="form-group">
      <span class="form-label">
        <label for="customer_state_code" class="control_label">
          {{ StateOptions.label }} <abbr title="Pflichtfeld">*</abbr>
        </label>
      </span>
      <span class="form-wrapper">
        <p class="form-control-static"  v-if="StateOptions.type === null">
          —
        </p>

        <input
            v-else-if="StateOptions.type === 'text'"
            v-model="customer.state_code"
            id="customer_state_code"
            name="customer[state_code]"
            class="form-control"
            required
        >

        <select
            v-model="customer.state_code"
            v-else-if="StateOptions.type === 'select'"
            id="customer_state_code"
            class="form-control"
            name="customer[state_code]"
            required
        >
          <option
              v-for="s in StateOptions.states"
              :key="s.code"
              :value="s.code"
              v-text="s.name"
          />
        </select>
      </span>
    </div>
  </div>
</template>

<script>
import { COUNTRIES, STATES, CountryCodeOptions, StateOptions } from "../../lib/CountryAndStates"

import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "villa_booking.customer_form" })

export default {
  props: {
    country:    { type: String, default: "" },
    state_code: { type: String, default: "" },
  },

  data() {
    return {
      customer: {
        country:    this.country,
        state_code: this.state_code,
      },
    }
  },

  computed: {
    countries: () => COUNTRIES,
    states:    () => STATES,

    CountryCodeOptions,
    StateOptions() {
      return StateOptions(this.customer.country)
    },
  },

  methods: {
    translate,
    t,
  },
}
</script>
