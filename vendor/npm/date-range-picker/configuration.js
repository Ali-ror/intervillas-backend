import Vue from "vue"
import { setup } from "@digineo/vue-translate"

const configuration = {
  icons: {
    btnOK:        ["fa", "fa-check"],
    btnCancel:    ["fa", "fa-times"],
    chevronLeft:  ["fa", "fa-chevron-left"],
    chevronRight: ["fa", "fa-chevron-right"],
  },
}

/**
 * Finds Font-Awesome icon classes for (known) icon identifiers.
 * @param {string} key Icon identifier
 * @return {string | undefined}
 */
export function getIcon(key) {
  const currentIcons = configuration.icons
  if (!Object.prototype.hasOwnProperty.call(currentIcons, key)) {
    return
  }
  return currentIcons[key]
}

export default { getIcon }

setup(Vue, {
  de: {
    drp: {
      btn: {
        ok:     "OK",
        cancel: "Abbrechen",
      },
      state: {
        blocked:  "nicht auswählbar",
        selected: "ausgewählt",
      },
      range_type: {
        days:   "Tage",
        nights: "Nächte",
      },
    },
  },

  en: {
    drp: {
      btn: {
        ok:     "OK",
        cancel: "Cancel",
      },
      state: {
        blocked:  "blocked dates",
        selected: "selected dates",
      },
      range_type: {
        days:   "days",
        nights: "nights",
      },
    },
  },
})
