import Vue from "vue"
import { setup } from "@digineo/vue-translate"
import locales from "../i18n.js"

import { setDefaultOptions } from "date-fns"
import { de, enUS } from "date-fns/locale"

// Sets up translate helper
setup(Vue, locales)

document.addEventListener("DOMContentLoaded", () => {
  setDefaultOptions(document.body.lang === "de"
    ? { locale: de, weekStartsOn: de.options.weekStartsOn }
    : { locale: enUS, weekStartsOn: enUS.options.weekStartsOn },
  )
})
