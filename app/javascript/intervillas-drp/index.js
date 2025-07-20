import Vue from "vue"

import DateRangePicker from "@digineo/date-range-picker"
Vue.use(DateRangePicker)

import vOutsideClick from "@digineo/v-outside-click"
Vue.directive("outside-click", vOutsideClick)

import BirthdayPicker from "./components/BirthdayPicker.vue"
Vue.component("BirthdayPicker", BirthdayPicker)

import SimpleDatePicker from "./components/SimpleDatePicker.vue"
Vue.component("SimpleDatePicker", SimpleDatePicker)
