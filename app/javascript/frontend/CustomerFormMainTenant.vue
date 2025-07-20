<template>
  <div>
    <div key="first_name" :class="formGroupClass('first_name')">
      <span class="form-label">
        <label for="booking_customer_attributes_first_name" class="control-label">
          {{ t("first_name") }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <input
            v-model="customer.first_name"
            id="booking_customer_attributes_first_name"
            class="form-control"
            name="booking[customer_attributes][first_name]"
            type="text"
            required
            disabled
        >
      </span>
    </div>

    <div key="last_name" :class="formGroupClass('last_name')">
      <span class="form-label">
        <label for="booking_customer_attributes_last_name" class="control-label">
          {{ t("last_name") }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <input
            v-model="customer.last_name"
            id="booking_customer_attributes_last_name"
            class="form-control"
            name="booking[customer_attributes][last_name]"
            type="text"
            required
            disabled
        >
      </span>
    </div>

    <div key="address" :class="formGroupClass('address')">
      <span class="form-label">
        <label for="booking_customer_attributes_address" class="control-label">
          {{ t("address") }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <input
            v-model="customer.address"
            id="booking_customer_attributes_address"
            class="form-control"
            name="booking[customer_attributes][address]"
            type="text"
            required
        >

        <span
            class="help-block m-0"
            v-for="(msg, i) in formGroupErrors('address')"
            :key="i"
            v-text="msg"
        />
      </span>
    </div>

    <div key="appnr" :class="formGroupClass('appnr')">
      <span class="form-label">
        <label for="booking_customer_attributes_appnr" class="control-label">
          {{ t("appnr") }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <input
            v-model="customer.appnr"
            id="booking_customer_attributes_appnr"
            class="form-control"
            name="booking[customer_attributes][appnr]"
            type="text"
            required
        >

        <span
            class="help-block m-0"
            v-for="(msg, i) in formGroupErrors('appnr')"
            :key="i"
            v-text="msg"
        />
      </span>
    </div>

    <div key="postal_code" :class="formGroupClass('postal_code')">
      <span class="form-label">
        <label for="booking_customer_attributes_postal_code" class="control-label">
          {{ t("postal_code") }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <input
            v-model="customer.postal_code"
            id="booking_customer_attributes_postal_code"
            class="form-control"
            name="booking[customer_attributes][postal_code]"
            type="text"
            required
        >

        <span
            class="help-block m-0"
            v-for="(msg, i) in formGroupErrors('postal_code')"
            :key="i"
            v-text="msg"
        />
      </span>
    </div>

    <div key="city" :class="formGroupClass('city')">
      <span class="form-label">
        <label for="booking_customer_attributes_city" class="control-label">
          {{ t("city") }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <input
            v-model="customer.city"
            id="booking_customer_attributes_city"
            class="form-control"
            name="booking[customer_attributes][city]"
            type="text"
            required
        >

        <span
            class="help-block m-0"
            v-for="(msg, i) in formGroupErrors('city')"
            :key="i"
            v-text="msg"
        />
      </span>
    </div>

    <div key="country" :class="formGroupClass('country')">
      <span class="form-label">
        <label for="booking_customer_attributes_country" class="control-label">
          {{ t("country") }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <select
            v-model="customer.country"
            id="booking_customer_attributes_country"
            class="form-control"
            name="booking[customer_attributes][country]"
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

        <span
            class="help-block m-0"
            v-for="(msg, i) in formGroupErrors('country')"
            :key="i"
            v-text="msg"
        />
      </span>
    </div>

    <div
        :class="formGroupClass('state_code')"
        key="state_code"
        v-if="StateOptions.type != null"
    >
      <span class="form-label">
        <label for="booking_customer_attributes_state_code" class="control-label">
          {{ StateOptions.label }}
          <img :src="arrowForm">
        </label>
      </span>
      <span class="form-wrapper">
        <input
            v-model="customer.state_code"
            v-if="StateOptions.type === 'text'"
            id="booking_customer_attributes_state_code"
            class="form-control"
            name="booking[customer_attributes][state_code]"
            type="text"
            required
        >

        <select
            v-model="customer.state_code"
            v-if="StateOptions.type === 'select'"
            id="booking_customer_attributes_state_code"
            class="form-control"
            name="booking[customer_attributes][state_code]"
            required
        >
          <option
              v-for="s in StateOptions.states"
              :key="s.code"
              :value="s.code"
              v-text="s.name"
          />
        </select>

        <span
            class="help-block m-0"
            v-for="(msg, i) in formGroupErrors('state_code')"
            :key="i"
            v-text="msg"
        />
      </span>
    </div>
  </div>
</template>

<script>
import arrowForm from "../images/arrow_form.png"

import { CountryCodeOptions, StateOptions } from "../lib/CountryAndStates"

import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "villa_booking.customer_form" })

export default {
  props: {
    firstName:  { type: String, default: "" },
    lastName:   { type: String, default: "" },
    address:    { type: String, default: "" },
    appnr:      { type: String, default: "" },
    postalCode: { type: String, default: "" },
    city:       { type: String, default: "" },
    country:    { type: String, default: "" },
    stateCode:  { type: String, default: "" },
    errors:     { type: Object, default: () => ({}) },
  },

  data() {
    return {
      customer: {
        first_name:  this.firstName,
        last_name:   this.lastName,
        address:     this.address,
        appnr:       this.appnr,
        postal_code: this.postalCode,
        city:        this.city,
        country:     this.country,
        state_code:  this.stateCode,
      },
    }
  },

  setup() {
    return { arrowForm }
  },

  computed: {
    CountryCodeOptions,
    StateOptions() {
      return StateOptions(this.customer.country)
    },
  },

  watch: {
    firstName(val) {
      this.customer.firstName = val
    },
    lastName(val) {
      this.customer.lastName = val
    },
    address(val) {
      this.customer.address = val
    },
    appnr(val) {
      this.customer.appnr = val
    },
    postalCode(val) {
      this.customer.postalCode = val
    },
    city(val) {
      this.customer.city = val
    },
    country(val) {
      this.customer.country = val
    },
    state_code(val) {
      this.customer.state_code = val
    },
  },

  methods: {
    t,

    formGroupClass(key) {
      return {
        "form-group": true,
        "has-error":  (key in this.errors) && this.errors[key].length,
      }
    },

    formGroupErrors(key) {
      return (key in this.errors) ? this.errors[key] : []
    },
  },
}
</script>
