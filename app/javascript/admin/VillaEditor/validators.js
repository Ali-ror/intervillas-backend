import {
  decimal,
  helpers,
  integer,
  minValue,
  required,
  requiredIf,
} from "vuelidate/lib/validators"

export {
  decimal,
  integer,
  minValue,
  required,
  requiredIf,
  countryCode,
  minLength,
  greaterThan,
  inCollection,
}

const COUNTRY_CODES = Object.freeze({
  US: true,
  ES: true,
})

const countryCode = helpers.withParams({
  type: "countryCode",
  cc:   Object.keys(COUNTRY_CODES),
}, val => !!COUNTRY_CODES[val])

const minLength = min => helpers.withParams({
  type: "minLength",
  min,
}, val => helpers.len(val) >= min)

// minValue === greaterThanOrEqualTo
const greaterThan = min => helpers.withParams({
  type: "greaterThan",
  min,
}, val => parseFloat(val) > min)

const inCollection = options => helpers.withParams({
  type:    "inCollection",
  options: options,
}, val => options.includes(val))

const LABELS = Object.freeze({
  required: Object.freeze({
    de: () => "muss ausgefüllt werden",
    en: () => "is required",
  }),
  minValue: Object.freeze({
    de: ({ min }) => `muss mindestens ${min} sein`,
    en: ({ min }) => `must be at least ${min}`,
  }),
  minLength: Object.freeze({
    de: ({ min }) => `wenigstens ${min} ${min === 1 ? "muss" : "müssen"} ausgewählt sein`,
    en: ({ min }) => `at least ${min} must be selected`,
  }),
  countryCode: Object.freeze({
    de: ({ cc }) => `unerwarteter Länder-Code (erlaubte Werte: ${cc.join(", ")})`,
    en: ({ cc }) => `unexpected country code (allowed values: ${cc.join(", ")})`,
  }),
  integer: Object.freeze({
    de: () => "muss eine ganze Zahl sein",
    en: () => "must be an integer",
  }),
  decimal: Object.freeze({
    de: () => "muss eine Zahl sein",
    en: () => "must be a number",
  }),
  greaterThan: Object.freeze({
    de: ({ min }) => `muss größer als ${min} sein`,
    en: ({ min }) => `must be larger than ${min}`,
  }),
  inCollection: Object.freeze({
    de: () => "ungültige Auswahl",
    en: () => "invalid selection",
  }),
})

export const errorsFor = (locale, base) => Object.keys(base.$params)
  .filter(e => typeof base[e] === "boolean" && !base[e])
  .map(e => LABELS[e][locale](base.$params[e]))
