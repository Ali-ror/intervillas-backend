const BASE_ID = new Date().valueOf()

const genId = (i => {
  return () => BASE_ID + ++i
})(1)

export class CurrencyValue {
  constructor({ id, value, _destroy }) {
    this.id = id || genId()
    this._value = value
    this._destroy = _destroy
  }

  get value() {
    return this._value
  }

  set value(val) {
    if (val == null || val === "") {
      this._value = null
      this._destroy = true
    } else {
      this._value = val
      this._destroy = false
    }
  }

  toJSON() {
    const { id, value, _destroy } = this
    return { id, value, _destroy: _destroy || undefined }
  }
}

export class Price {
  constructor(attrs) {
    const { subject, amount } = Object.assign({
      subject: null,
      amount:  1,
    }, attrs)

    this.subject = subject
    if (subject === "daily") {
      this.amount = amount
    }

    this._values = {
      eur: null,
      usd: null,
    }
    this._destroy = false
    this._dirty = false
  }

  get label() {
    switch (this.subject) {
    case "daily":
      return `${this.amount} Tag${this.amount === 1 ? "" : "e"}`
    case "deposit":
      return "Kaution"
    case "training":
      return "Anlieferung"
    default:
      return `?? ${this.subject} ??`
    }
  }

  get destroy() {
    return this._destroy
  }

  set destroy(val) {
    this._destroy = val
    if (this._values.eur) {
      this._values.eur._destroy = val
    }
    if (this._values.usd) {
      this._values.usd._destroy = val
    }
  }

  /** @returns {Number?} */
  get eur() {
    return this._values.eur?.value
  }

  /** @param {Number} value */
  set eur(value) {
    if (this._values.eur) {
      this._values.eur.value = value
    } else {
      this.setValue({ currency: "EUR", value })
    }

    this._dirty = true
  }

  /** @returns {Number?} */
  get usd() {
    return this._values.usd?.value
  }

  /** @param {Number} value */
  set usd(value) {
    if (this._values.usd) {
      this._values.usd.value = value
    } else {
      this.setValue({ currency: "USD", value })
    }

    this._dirty = true
  }

  /**
   * Stores a new value for the given currency, remembers its record ID, and
   * skips dirty tracking.
   * This methods is intended for the initialization phase.
   *
   * @param {any} record
   * @param {Number?} record.id Database ID
   * @param {"EUR"|"USD"} record.currency
   * @param {Number} record.value
   */
  setValue({ id, currency, value }) {
    switch (currency) {
    case "EUR":
      this._values.eur = new CurrencyValue({ id, value, _destroy: this._destroy })
      break
    case "USD":
      this._values.usd = new CurrencyValue({ id, value, _destroy: this._destroy })
      break
    default:
      throw new Error(`unknown currency: ${currency}`)
    }
  }

  /**
   * Generic getter, return the value for the given currency.
   * @param {"EUR"|"USD"} currency
   */
  get(currency) {
    switch (currency) {
    case "EUR":
      return this.eur
    case "USD":
      return this.usd
    default:
      throw new Error(`unknown currency: ${currency}`)
    }
  }

  /**
   * Generic setter, store the value for the given currency.
   * @param {"EUR"|"USD"} currency
   */
  set(currency, value) {
    switch (currency) {
    case "EUR":
      this.eur = value
      break
    case "USD":
      this.usd = value
      break
    default:
      throw new Error(`unknown currency: ${currency}`)
    }
  }

  /**
   * If `this` contains a value for `currency` it is returned, otherwise
   * a new value is calculated using the given exchange `rate`.
   *
   * @param {"EUR"|"USD"} currency target currency
   * @param {Number} rate exchange rate for EUR to `currency`
   */
  convertTo(currency, rate) {
    if (rate == null || rate === 0) {
      return
    }
    if (currency === "EUR" && this.eur == null && this.usd != null) {
      return this.usd / rate
    }
    if (currency === "USD" && this.eur != null && this.usd == null) {
      return this.eur * rate
    }
    return
  }

  toJSON() {
    const { subject, amount } = this

    const json = []
    const addCurrencyValue = (currency, currVal) => {
      if (!currVal) {
        return
      }

      const { id, value, _destroy } = currVal.toJSON()
      json.push({
        id,
        value,
        subject,
        currency,
        amount,
        _destroy,
      })
    }

    addCurrencyValue("EUR", this._values.eur)
    addCurrencyValue("USD", this._values.usd)
    return json
  }
}

export class Discount {
  constructor(attrs) {
    const { id, description, percent, days_before, days_after } = Object.assign({
      id:          null,
      description: null,
      percent:     null,
      days_before: null,
      days_after:  null,
    }, attrs)

    this.id = id || genId()
    this.persisted = this.id < BASE_ID
    this.description = description
    this._percent = percent
    this._before = days_before
    this._after = days_after
    this._dirty = false
    this.destroy = false
  }

  get label() {
    switch (this.description) {
    case "christmas":
      return "Weihnachten"
    case "easter":
      return "Ostern"
    default:
      return `?? ${this.description} ??`
    }
  }

  get percent() {
    return this._percent
  }

  set percent(val) {
    this._percent = val
    this._dirty = true
  }

  get before() {
    return this._before
  }

  set before(val) {
    this._before = val
    this._dirty = true
  }

  get after() {
    return this._after
  }

  set after(val) {
    this._after = val
    this._dirty = true
  }

  toJSON() {
    const { id, description, percent, before, after, destroy } = this

    return {
      id,
      description,
      percent,
      days_before: before,
      days_after:  after,
      _destroy:    destroy || undefined,
    }
  }
}
