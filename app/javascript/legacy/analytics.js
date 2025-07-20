/* eslint no-console:0 */
/* global ga process */

(function(env, data) {
  if (!data.ua || !data.domain) {
    return
  }
  switch (env) {
  case "development":
  case "staging":
    var slice = Array.prototype.slice
    window.ga = function() {
      console.info.call(console, slice.call(arguments))
    }
    break

  case "production":
    window["GoogleAnalyticsObject"] = "ga"
    window.ga = window.ga || function() {
      (ga.q = ga.q || []).push(arguments)
    }

    ga.l = +new Date()
    var el = document.createElement("script")
    el.type = "text/javascript"
    el.async = true
    el.src = "//www.google-analytics.com/analytics.js"
    var ref = (document.getElementsByTagName("head")[0] || document.getElementsByTagName("body")[0])
    ref.appendChild(el)
    break

  default:
    return
  }

  ga("create", data.ua, "auto")
  ga("set", "anonymizeIp", true)
  ga("set", "hostname", data.domain)

  if (data.page) {
    ga("send", "pageview", data.page)
  } else {
    ga("send", "pageview")
  }
})(process.env.NODE_ENV, document.body.dataset)
