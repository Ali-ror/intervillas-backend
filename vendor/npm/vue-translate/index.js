import deepmerge from "deepmerge"

const escape = str => str.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")

const has = (obj, prop) => obj !== null && Object.prototype.hasOwnProperty.call(obj, prop)

let needFilter = true

export function setup(Vue, translations) {
  if (window.__locale_data__ === undefined) {
    window.__locale_data__ = {}
  }

  window.__locale_data__ = deepmerge(window.__locale_data__, translations)

  if (needFilter) {
    Vue.filter("translate", translate)
    Vue.filter("pluralize", pluralize)
    needFilter = false
  }
}

/**
 * Translates something, much like `I18n.translate` in Rails templates.
 *
 * @param {string} key path to translation key
 * @param {object} params key/value pairs used for interpolation. "scope" is a special key,
 * @returns {string | object}
 *    Returns the translated `key`, if `key` points to a leaf entry in
 *    the translation tree. Otherwise returns the subtree at the given
 *    path.
 */
export function translate(key, params = {}) {
  try {
    const node = resolvePath(key, params["scope"])

    // pattern-replace strings only if node is a leaf (i.e. string)
    if (typeof node === "string") {
      return Object.keys(params).filter(k => k !== "scope").reduce((t, key) => {
        const val = params[key],
              re = new RegExp(`%\\{${escape(key)}\\}`, "g")
        return t.replace(re, val)
      }, node)
    }
    // return non-leaf entries (arrays, objects) as a whole
    return node
  } catch (err) {
    return err.message
  }
}

/**
 * Interpolates a number into a pluraliation object (zero, one, other).
 *
 * @example
 *    __locale_data__.en.foo = {
 *       zero:  "no foos",
 *       one:   "1 foo",
 *       other: "%{count} foos",
 *    }
 *    pluralize(12, "foo")  //=> "12 foos"
 *
 *    // "zero" and "one" are optional:
 *    __locale_data__.en.bar = { other: "%{count} bars" }
 *    pluralize(1, "bar") //=> "1 bars"
 *
 * @param {number} count Number modifier
 * @param {string} key path to pluralization key
 */
export function pluralize(count, key) {
  try {
    const node = resolvePath(key)

    if (typeof node === "object") {
      const n = Math.floor(count)
      if (n === 0 && has(node, "zero")) {
        return node.zero
      }
      if (n === 1 && has(node, "one")) {
        return node.one
      }
      if (has(node, "other")) {
        return node.other.replace(/%\{count\}/, n.toString())
      }
    }

    const msg = `Not pluralizable: ${key}`
    return msg
  } catch (err) {
    return err.message
  }
}

/**
 * Resolves a key path.
 *
 * @param {string} key (sub-) path to translation key
 * @param {string?} scope optinal path prefix
 * @throws Throw if the key path cannot be resolved, i.e. the key does not exist.
 */
function resolvePath(key, scope = null) {
  let tree = window.__locale_data__
  const path = [document.body.lang]
  if (scope) {
    path.push(...scope.toString().split("."))
  }

  path.push(...key.toString().split("."))

  for (let i = 0, len = path.length; i < len; ++i) {
    const part = path[i]
    if (has(tree, part)) {
      tree = tree[part]
      continue
    }

    throw new Error(`Translation missing: ${path.join(".")}`)
  }
  return tree
}
