import Vue from "vue"
Vue.config.productionTip = false

import * as Sentry from "@sentry/vue"

if (window.SENTRY_CONFIG) {
  const { dsn, environment, release } = JSON.parse(atob(window.SENTRY_CONFIG))
  Sentry.init({
    Vue,
    dsn,
    environment,
    release,
    enabled:      true,
    integrations: [Sentry.browserTracingIntegration()],
    denyUrls:     [
      "google-analytics.com",
      "www.google-analytics.com",
      "analytics.google.com",
      /\/analytics\.js$/,
    ],
    sendClientReports: false,
  })
}
