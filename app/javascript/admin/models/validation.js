import validate from "validate.js"
import { makeDate } from "../../lib/DateFormatter"
import { startOfDay, format } from "date-fns"

validate.formatters.simple = errors => {
  return errors.map(err => err.validator)
}

validate.validators.datetime.parse = function(value, options) {
  const date = makeDate(value)

  return options.dateOnly
    ? startOfDay(date).valueOf()
    : date.valueOf()
}

validate.validators.datetime.format = function(value, options) {
  const fmt = options.dateOnly
    ? "yyyy-MM-dd"
    : "yyyy-MM-dd HH:mm:ss"
  return format(makeDate(value), fmt)
}

validate.validators.email.PATTERN = /^[^@\s]+@[^@\s]+$/

const i18n = {
  presence: {
    message: "muss ausgefüllt werden",
  },
  length: {
    notValid:    "^Länge ist nicht gültig",
    wrongLength: "^Länge ist ungültig (sollte %{count} Zeichen sein)",
    tooShort:    "ist zu kurz (minimal %{count} Zeichen)",
    tooLong:     "ist zu lang (maximal %{count} Zeichen)",
  },
  numericality: {
    message:                 "ist keine gültige Zahl",
    notValid:                "ist keine Zahl",
    notInteger:              "muss eine ganze Zahl sein",
    notGreaterThan:          "muss größer als %{count} sein",
    notGreaterThanOrEqualTo: "muss größer oder gleich %{count} sein",
    notEqualTo:              "darf nicht %{count} sein",
    notLessThan:             "muss kleiner als %{count} sein",
    notLessThanOrEqualTo:    "muss kleiner oder gleich %{count} sein",
    notDivisibleBy:          "muss durch %{count} zu teilen sein",
    notOdd:                  "muss ungerade sein",
    notEven:                 "muss gerade sein",
  },
  datetime: {
    notValid: "ist kein gültiges Datum",
    tooEarly: "darf nicht vor %{date} liegen",
    tooLate:  "muss vor %{date} liegen",
  },
  date: {
    notValid: "ist kein gültiges Datum",
    tooEarly: "darf nicht vor %{date} liegen",
    tooLate:  "muss vor %{date} liegen",
  },
  format: {
    message: "ist ungültig",
  },
  inclusion: {
    message: "^%{value} ist kein erlaubter Wert",
  },
  exclusion: {
    message: "^%{value} nicht erlaubt",
  },
  email: {
    message: "ist keine gültige E-Mail-Adresse",
  },
  equality: {
    message: "muss den gleichen Wert wie %{attribute} haben",
  },
  url: {
    message: "ist keine gültige URL",
  },
}

Object.keys(i18n).forEach(k => {
  validate.extend(validate.validators[k], i18n[k])
})

export default validate
