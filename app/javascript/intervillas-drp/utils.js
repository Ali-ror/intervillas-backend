import axios from "axios"

import { StatusCreated, StatusMovedPermanently, StatusFound, StatusSeeOther, StatusInternalServerError } from "../lib/http_status"

// Wenn window.location direkt in einem XMLHttpRequest verändert wird, nimmt
// der Browser an, dass dies noch zum AJAX-Request gehört und der User wechselt
// dann nicht die Seite...
const gotoURL = url => setTimeout(() => window.location.assign(url), 50)

const followRedirect = response => {
  const location = response.headers.location
  if (location && [StatusMovedPermanently, StatusFound, StatusSeeOther].includes(response.status)) {
    gotoURL(location)
    return
  }

  const url = response.data && response.data.url
  if (url && [StatusCreated, StatusFound].includes(response.status)) {
    gotoURL(url)
    return
  }
  return response
}

const safeVerb = verb => ["get", "options", "head"].includes(verb.toLowerCase())

/**
 * Determines whether the given URL is used for a Cross-Domain request.
 *
 * See https://github.com/rails/rails/blob/master/actionview/app/assets/javascripts/rails-ujs/utils/ajax.coffee.
 *
 * @param {string} url The target URL.
 */
const isCrossDomain = url => {
  const origin = document.createElement("a"),
        target = document.createElement("a")
  origin.href = location.href

  try {
    target.href = url

    return !(((!target.protocol || target.protocol === ":") && !target.host)
      || (`${origin.protocol}//${origin.host}` === `${target.protocol}//${target.host}`))
  } catch (_error) {
    // parsing error, assume Cross-Domain
    return true
  }
}

const csrf = {
  name:   "X-CSRF-Token",
  _token: null,
  token() {
    this._token || (this._token = document.querySelector("meta[name=csrf-token]"))
    return this._token ? this._token.content : null
  },
}

// a Rails-compatible JSON-API client
export const railsClient = (function() {
  const client = axios.create({
    withCredentials: true,
    responseType:    "json",
    xsrfHeaderName:  csrf.name,
    xsrfCookieName:  undefined,

    // do not fail on 400's errors (unprocessable entity = 422)
    validateStatus: status => status < StatusInternalServerError,
  })

  client.defaults.headers.common["Accept"] = "application/json"
  for (let m = ["post", "put", "patch"], i = 0, len = m.length; i < len; ++i) {
    client.defaults.headers[m[i]]["Content-Type"] = "application/json;charset=utf-8"
  }

  client.interceptors.request.use(function(config) {
    if (safeVerb(config.method) || isCrossDomain(config.url)) {
      return config
    }
    if (!config.headers[csrf.name]) {
      config.headers[csrf.name] = csrf.token()
    }
    return config
  })

  return client
})()

const compare = {
  arrays(a, b) {
    return a.every((val, idx) => val === b[idx])
  },

  sets(a, b) {
    const other = new Set(b)
    return a.every(val => other.has(val))
  },
}

export default {
  /**
   * Holt JSON-Daten von der angegbenen URL ab.
   * @param {string} url
   * @param {AbortSignal=} signal Allows request cancelling.
   */
  async fetchJSON(url, signal = undefined) {
    const { data } = await railsClient.get(url, { signal })
    return data
  },

  /**
   * Sendet JSON-Daten an die übergebene URL mit der angegebenen Methods.
   * Wenn `body` ein String ist, wird angenommen, dass es sich dabei bereits
   * um JSON-kodierte Daten handelet. Ansonsten wird `JSON.stringify(body)`
   * übertragen.
   * @param {string} method post, patch, put
   * @param {string} url
   * @param {string | object} data
   */
  requestJSON(method, url, data) {
    if (data && (typeof data !== "string" || !(data instanceof String))) {
      data = JSON.stringify(data)
    }
    return railsClient.request({ method, url, data })
      .then(followRedirect)
      .then(response => response ? response.data : {})
  },

  postJSON(url, body) {
    return this.requestJSON("post", url, body)
  },

  putJSON(url, body) {
    return this.requestJSON("put", url, body)
  },

  patchJSON(url, body) {
    return this.requestJSON("patch", url, body)
  },

  deleteJSON(url, body) {
    return this.requestJSON("delete", url, body)
  },

  /**
   * Duplicates/clones any object or primitive via serialization to and
   * parsing of JSON. The same restrictions apply as to `JSON.strigify`;
   * most notably, circular rerefences are not supported. Also, if `o`
   * (or any property, recursively) implements a `toJSON()` method, it
   * can circumvent a true duplicate.
   *
   * @template T
   * @param {T} o Object or primitive to duplicate
   * @return {T} A duplicate
   */
  dup(o) {
    return JSON.parse(JSON.stringify({ o })).o
  },

  /**
   * Checks if two arrays contain the same items. Item equality is checked
   * with `===`, so this only works for primitive items, not objects.
   *
   * @param {any[]} a
   * @param {any[]} b
   * @param {boolean} ignoreOrder ignores order of elements, false by default
   */
  equalArrays(a, b, ignoreOrder = false) {
    return a === b || ( // either same array, or:
      a != null && b != null // both present and
      && a.length === b.length // same length and
      && ignoreOrder
        ? compare.sets(a, b)
        : compare.arrays(a, b) // identical items
    )
  },
}
