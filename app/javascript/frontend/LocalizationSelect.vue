<template>
  <div
      id="l10n-select"
      class="py-3 py-md-4"
      :class="{ hidden: saved }"
  >
    <div class="container py-md-2">
      <form class="d-md-flex justify-content-between align-items-center" @submit.prevent="save">
        <p class="mb-3 mb-md-0 mr-0 mr-md-3" v-text="texts.description" />

        <div class="input-group input-group-sm mb-3 mb-md-0 ml-0 ml-md-auto">
          <label
              for="l10n-select-locale"
              class="input-group-addon"
              v-text="texts.locale"
          />
          <select
              id="l10n-select-locale"
              v-model="selectedLocale"
              name="l10n-select-locale"
              class="form-control"
          >
            <option
                v-for="(text, loc) in locales"
                :key="loc"
                :value="loc"
                v-text="text"
            />
          </select>
        </div>

        <div v-if="currency !== ''" class="input-group input-group-sm mb-3 mb-md-0 ml-0 ml-md-3">
          <label
              for="l10n-select-currency"
              class="input-group-addon"
              v-text="texts.currency"
          />
          <select
              id="l10n-select-currency"
              v-model="selectedCurrency"
              name="l10n-select-currency"
              class="form-control"
          >
            <option
                v-for="(text, cur) in currencies"
                :key="cur"
                :value="cur"
                v-text="text"
            />
          </select>
        </div>

        <div class="text-right ml-0 ml-md-3">
          <button
              type="submit"
              class="btn btn-sm btn-default"
              :disabled="saving"
          >
            <i v-if="saving" class="fa fa-spinner fa-pulse" />
            {{ texts.save }}
          </button>
        </div>

        <div class="ml-0 ml-md-3">
          <a
              href="#"
              class="text-muted"
              :title="texts.dismiss"
              @click.prevent="dismiss"
          >
            <i class="fa fa-2x fa-times" />
          </a>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import Cookies from "js-cookie"
import Utils from "../intervillas-drp/utils"

// we need two cookies, because server-side handling is a bit convoluted
const LOCALE_COOKIE = "l10n-locale",
      CURRENCY_COOKIE = "l10n-currency"

function storeCookies({ locale, currency }) {
  const { hostname, protocol } = window.location

  const domain = hostname === "localhost"
    ? "localhost"
    : "." + hostname.split(".").slice(-2).join(".")

  const options = {
    expires:  20 * 365 + 20, // 20yrs from now (including leap days)
    path:     "/",
    domain,
    secure:   protocol === "https:",
    sameSite: "lax",
  }

  console.log(options)
  Cookies.set(LOCALE_COOKIE, locale, options)
  Cookies.set(CURRENCY_COOKIE, currency, options)
}

// can't use vue-translate here; it would give us only one language
const TEXT = Object.freeze({
  de: {
    description: "Basierend auf Ihren Browsereinstellungen haben wir folgende Auswahl für Sie getroffen:",
    locale:      "Sprache",
    currency:    "Preise",
    save:        "Speichern",
    dismiss:     "Einstellungen beibehalten",
    locales:     { de: "Deutsch", en: "Englisch" },
    currencies:  { EUR: "Euro", USD: "US-Dollar" },
  },
  en: {
    description: "Based on your browser settings, we've chosen the following preferences for you:",
    locale:      "Language",
    currency:    "Prices",
    save:        "Save",
    dismiss:     "keep settings",
    locales:     { de: "German", en: "English" },
    currencies:  { EUR: "in Euro", USD: "in US Dollar" },
  },
})

export default {
  props: {
    locale:   { type: String, default: null, validator: v => ["", "de", "en"].includes(v) },
    currency: { type: String, default: "", validator: v => ["", "EUR", "USD"].includes(v) },
  },

  data() {
    return {
      selectedLocale:   this.locale || "en",
      selectedCurrency: this.currency,
      appLocale:        document.body.lang,
      appCurrency:      document.body.dataset.currency,
      saved:            false,
      saving:           false,
    }
  },

  computed: {
    texts() {
      if (this.selectedLocale in TEXT) {
        return TEXT[this.selectedLocale]
      }
      return TEXT.en
    },

    locales() {
      const { de, en } = this.texts.locales
      return {
        de: `🇩🇪 ${de}`,
        en: `🇺🇸 ${en}`,
      }
    },

    currencies() {
      const { EUR, USD } = this.texts.currencies
      return { EUR, USD }
    },
  },

  methods: {
    dismiss() {
      const { appLocale: locale, appCurrency: currency } = this
      storeCookies({ locale, currency })
      this.saved = true
    },

    async save() {
      const { selectedLocale: locale, selectedCurrency: currency } = this
      this.saving = true

      const { url } = await Utils.patchJSON("/api/localization", {
        locale,
        ...(currency === "" ? {} : { currency }),
        path: [location.pathname, location.search].join(""),
      })
      if (url) {
        window.location = url
      }

      this.saved = true
    },
  },
}
</script>

<style lang="scss">
  #l10n-select {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;

    background: #fff;
    z-index: 1000;
  }
</style>
