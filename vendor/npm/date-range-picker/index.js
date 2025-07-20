import VOutsideClick from "@digineo/v-outside-click"

export default function install(Vue) {
  Vue.directive("outside-click", VOutsideClick)
}

import SinglePicker from "./components/SinglePicker.vue"
import RangePicker from "./components/RangePicker.vue"
import Configuration from "./configuration"
import Caption from "./caption"
import { DateRange } from "./DateRange"
import Collection from "./pickable/collection"
import Day from "./pickable/day"
import { absDiffDays, getLocaleData } from "./utils"

export {
  SinglePicker,
  RangePicker,
  Configuration,
  Caption,
  DateRange,
  Collection,
  Day,

  absDiffDays,
  getLocaleData,
}
