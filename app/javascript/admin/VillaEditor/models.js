/**
 * @file All models needed to display and mutate a Villa in the Vue layer.
 *
 * It is expected to fetch collections of supplemental data first: Only
 * after seting up known owners and managers, plus the (correct) tag
 * hierarchy, `new Villa()` returns a sensible object. To setup the
 * collections, you could invoke `CACHE.build()`.
 *
 * Do not use `new Villa()` nor `CACHE.build()` though.
 *
 * You want setup the build context with `Villa.build`, which expects
 * both the attributes for the Villa AND the supplemental collections,
 * and returns a properly setup Villa instance.
 *
 * All this is to hide the inter-model relations from the Vue layer.
 * Among other things, the Villa constructor will create zero-count tags
 * for all Tags (for which it must need to know all available Tags),
 * empty Desciptions (dito), etc. The `toJSON()` method knows how to
 * construct a proper object for the (Rails) API endpoint. This limits
 * the logic needed in each Vue component, but of course concentrates it
 * here.
 *
 * TODO: "Cache" is a terrible name. It actually represents a local DB
 * copy of the objects needed to fully describe a Villa (whether or not
 * those objects are directly associated with the Villa).
 */

import { has } from "../../lib/has"

/**
 * Cachable provides static methods to access a private cache. This is
 * used for example to resolve a `category_id` to a `Category` instance.
 */
class Cachable {
  /**
   * Retrieves a Cachable with the given ID.
   * @param {Number} id primary key
   * @returns {Cachable}
   */
  static byID(id) {
    return CACHE.get(this, id)
  }

  /**
   * Retrieves all Cachables.
   * @returns {Cachable[]} the cached instance
   */
  static all() {
    return Object.values(CACHE[this._cachekey])
  }

  constructor(id) {
    this.id = id
  }
}

export class Area {
  constructor(id, category_id, subtype, beds_count) {
    this.id = id
    this.category_id = category_id
    this.subtype = subtype
    this.taggings = Category.byID(category_id).tag_ids.reduce((tags, tid) => {
      tags[tid] = 0
      return tags
    }, {})
    this.beds_count = beds_count

    this._destroy = false
  }

  get category() {
    return Category.byID(this.category_id)
  }

  get newRecord() {
    return !this.id || this.id <= 0
  }

  toJSON() {
    const { id, _destroy, category_id, subtype, taggings, beds_count } = this
    return {
      id,
      category_id,
      subtype,
      taggings: denormalizeTagList(taggings),
      beds_count,
      _destroy,
    }
  }
}

export class VillaPrice {
  constructor({ id, currency, base_rate, additional_adult, children_under_6, children_under_12, cleaning, deposit, updated_at } = {}) {
    this.id = id
    this.base_rate = new Currency({ currency, value: base_rate })
    this.additional_adult = new Currency({ currency, value: additional_adult })
    this.children_under_6 = new Currency({ currency, value: children_under_6 })
    this.children_under_12 = new Currency({ currency, value: children_under_12 })
    this.cleaning = new Currency({ currency, value: cleaning })
    this.deposit = new Currency({ currency, value: deposit })
    this.updated_at = updated_at
    this.currency = currency
    this._destroy = false
  }

  toJSON() {
    // omits updated_at
    const { id, currency, _destroy, base_rate, additional_adult, children_under_6, children_under_12, cleaning, deposit } = this
    return { id, currency, _destroy, base_rate, additional_adult, children_under_6, children_under_12, cleaning, deposit }
  }
}

export class Currency {
  constructor({ value, currency = "EUR" } = {}) {
    this.value = value
    this.currency = currency
  }

  // Hier muss nur der Zahlwert kodiert werden, da die Währung bereits Teil der
  // Container-Variable ist (z.B. `villa_price_eur`).
  toJSON() {
    if (!Number.isFinite(this.value)) { // null, undefined, (empty) string
      return null
    }
    // Wir runden auf zwei Nachkommastellen.
    return Math.round(this.value * 100) / 100
  }
}

export class HolidayDiscount {
  constructor(id, description, percent, days_before, days_after) {
    this.id = id
    this.description = description
    this.percent = percent
    this.days_before = days_before
    this.days_after = days_after

    this._destroy = false
  }

  get newRecord() {
    return !this.id || this.id <= 0
  }

  toJSON() {
    return {
      id:          this.id,
      _destroy:    this._destroy,
      description: this.description,
      percent:     this.percent,
      days_before: this.days_before,
      days_after:  this.days_after,
    }
  }
}

export class Description extends Cachable {
  constructor(id, category_id, key, label, de, en) {
    super(id)
    this.category_id = category_id
    this.key = key
    this.label = label
    this.de = de || null
    this.en = en || null
  }

  get category() {
    return Category.byID(this.category_id)
  }

  get hasRichFormatting() {
    return this.key !== "header"
  }

  toJSON() {
    return {
      id:          this.id,
      category_id: this.category_id,
      key:         this.key,
      de:          this.de,
      en:          this.en,
    }
  }
}

export class Tag extends Cachable {
  constructor(id, category_id, countable, description) {
    super(id)
    this.category_id = category_id
    this.countable = !!countable
    this.description = description
  }

  get category() {
    return Category.byID(this.category_id)
  }
}

export class Domain extends Cachable {
  constructor(id, name) {
    super(id)
    this.name = name
  }
}

export class Calendar extends Cachable {
  constructor(id, url, name) {
    super(id)
    this.url = url
    this.name = name

    this._destroy = false
  }

  get newRecord() {
    return !this.id || this.id <= 0
  }

  toJSON() {
    return {
      id:       this.id,
      _destroy: this._destroy,
      url:      this.url,
      name:     this.name,
    }
  }
}

export class Category extends Cachable {
  static areaSubtypes() {
    Category.all()
      .filter(cat => cat.multiple_types)
      .reduce((acc, cur) => acc.concat(cur.multiple_types), [])
  }

  static byName(name) {
    const all = Category.all()
    for (let i = 0, len = all.length; i < len; ++i) {
      if (all[i].name === name) {
        return all[i]
      }
    }
  }

  constructor(id, name, label, multiple_types) {
    super(id)
    this.name = name
    this.label = label
    this.multiple_types = multiple_types
    this.tag_ids = []
    this.descriptions = {}
  }

  get tags() {
    return this.tag_ids.map(id => Tag.byID(id))
  }

  addDescription(desc) {
    this.descriptions[desc.key] = desc
  }
}

export class Contact extends Cachable {
  constructor(id, name, emails) {
    super(id)
    this.name = name
    this.emails = emails
  }
}

export class Boat extends Cachable {
  static byAssignability(assignability) {
    return Boat.all()
      .filter(boat => boat.assignability[assignability])
      .sort((a, b) => a.compare(b))
  }

  static findOrCreate(id, name) {
    let boat = Boat.byID(id)
    if (!boat) {
      boat = new Boat(id, name)
      CACHE.set(this, id, boat)
    }
    return boat
  }

  constructor(id, name) {
    super(id)
    this.name = name
    this.assignability = {
      exclusive: false,
      optional:  false,
    }

    const i = name.lastIndexOf("/")
    if (i >= 0 && i + 1 < name.length) {
      this.sortKey = name.substring(i + 1).trim().toLowerCase()
    }
  }

  compare(other) {
    if (this.sortKey && other.sortKey && this.sortKey !== other.sortKey) {
      return this.sortKey.localeCompare(other.sortKey)
    }
    return this.id - other.id
  }
}

export class AssignableBoat {
  constructor() {
    this._inclusion = "none"
    this.exclusive_id = null
    this.optional_ids = []
  }

  get inclusion() {
    return this._inclusion
  }

  set inclusion(val) {
    if (val === "none") {
      this._inclusion = val
      this.exclusive_id = null
      this.optional_ids = []
    } else if (val === "inclusive") {
      this._inclusion = val
      this.exclusive_id = null
    } else if (val === "optional") {
      this._inclusion = val
      this.optional_ids = []
    } else {
      throw new Error(`unexpected boat inclusion: ${val}`)
    }
  }

  toJSON() {
    const data = { inclusion: this.inclusion }
    if (this.inclusion === "inclusive") {
      data.exclusive_id = this.exclusive_id
    } else if (this.inclusion === "optional") {
      data.optional_ids = this.optional_ids
    }
    return data
  }
}

// Properties of a Villa instance not related to any associated object.
// Used in both `Villa.build` and `Villa.prototype.toJSON`.
export const VILLA_PRIMITIVES = Object.freeze([
  "name",
  "active",
  "minimum_booking_nights",
  "minimum_people",
  "buyable",
  "build_year",
  "last_renovation",
  "safe_code",
  "phone",
  "manager_id",
  "owner_id",
  "street",
  "postal_code",
  "locality",
  "region",
  "country",
  "living_area",
  "pool_orientation",
  "latitude",
  "longitude",
  "additional_properties",
  "energy_cost_calculation",
])

class Cache {
  constructor(...classes) {
    this._classes = []

    for (let i = 0, len = classes.length; i < len; ++i) {
      this.remember(classes[i])
    }
  }

  remember(klass) {
    if (this._classes.includes(klass)) {
      return
    }

    this._classes.push(klass)
    Object.defineProperty(klass, "_cachekey", {
      configurable: false,
      writable:     false,
      enumerable:   false,
      value:        Symbol(klass.name),
    })

    this[klass._cachekey] = {}
  }

  reset() {
    for (let i = 0, len = this._classes.length; i < len; ++i) {
      const klass = this._classes[i]
      this[klass._cachekey] = {}
    }
  }

  get(klass, id) {
    return this[klass._cachekey][id]
  }

  set(klass, id, val) {
    this[klass._cachekey][id] = val
  }

  build(data) {
    this.reset()

    // build domains
    for (let i = 0, len = (data.domains || []).length; i < len; ++i) {
      const { id, name } = data.domains[i]
      this.set(Domain, id, new Domain(id, name))
    }
    // build contacts
    for (let i = 0, len = (data.contacts || []).length; i < len; ++i) {
      const { id, name, emails } = data.contacts[i]
      this.set(Contact, id, new Contact(id, name, emails))
    }
    // build categories/tags
    for (let i = 0, ilen = (data.categories || []).length; i < ilen; ++i) {
      const c = data.categories[i]
      this.set(Category, c.id, new Category(c.id, c.name, c.label, c.multiple_types))

      for (let j = 0, jlen = (c.descriptions || []).length; j < jlen; ++j) {
        const { key, label } = c.descriptions[j]
        const d = new Description(null, c.id, key, label)
        this.get(Category, c.id).addDescription(d)
      }
      for (let j = 0, jlen = (c.tags || []).length; j < jlen; ++j) {
        const t = c.tags[j]
        this.set(Tag, t.id, new Tag(t.id, c.id, t.countable, t.description))
        this.get(Category, c.id).tag_ids.push(t.id)
      }
    }
    // build boats
    for (let i = 0, len = (data.exclusive_boats || []).length; i < len; ++i) {
      const { id, name } = data.exclusive_boats[i],
            boat = Boat.findOrCreate(id, name)
      boat.assignability.exclusive = true
    }
    for (let i = 0, len = (data.optional_boats || []).length; i < len; ++i) {
      const { id, name } = data.optional_boats[i],
            boat = Boat.findOrCreate(id, name)
      boat.assignability.optional = true
    }
  }
}

const CACHE = new Cache(Boat, Category, Contact, Description, Domain, Tag)

const denormalizeTagList = taggings => Object.entries(taggings)
  .filter(t => t[1] > 0)
  .map(t => ({ tag_id: Number(t[0]), amount: t[1] }))

export class Errors {
  constructor(errors) {
    Object.keys(errors).forEach(key => {
      Errors.set(this, key, errors[key])
    })
  }

  /** @private */
  static set(instance, key, val) {
    this.toPath(key).reduce((obj, k, depth, path) => {
      if (depth === path.length - 1) {
        obj[k] = val
        return
      }
      if (!has(obj, k)) {
        obj[k] = {}
      }
      return obj[k]
    }, instance)
  }

  /**
   * Transforms an object path key to an array of key elements, such that
   * recursively accessing an object with that series of key elements becomes
   * possible.
   *
   * Examples (input => result):
   *
   *    "foo.bar"     => ["foo", "bar"]
   *    "foo[0]"      => ["foo", "0"]
   *    "foo[0].bar"  => ["foo", "0", "bar"]
   *
   * Attention, this is a very simple transformation; it just replaces
   * `[` and `]` with `.`, collapses consecutive `.` into one and finally
   * splits on the dots.
   *
   *    "foo[].bar" -> "foo...bar" -> "foo.bar" => ["foo", "bar"]
   *    "foo['bar.baz']" => ["foo", "'bar", "baz'"]
   *
   * For the purpose of this Errors class, those are considered invalid
   * input.
   *
   * @param {String} key
   * @private
   */
  static toPath(key) {
    return key.replace(/\[|\]/g, ".").replace(/\.+/g, ".").split(".")
  }
}

export class Villa {
  static build(attributes, collections) {
    if (!attributes) {
      attributes = {}
    }
    if (collections) {
      CACHE.build(collections)
    }

    const villa = new Villa(attributes.id)
    VILLA_PRIMITIVES.forEach(att => {
      if (has(attributes, att)) {
        villa[att] = attributes[att]
      }
    })

    // just informational
    villa.booking_pal_product = attributes.booking_pal_product
    villa.amenity_ids = new Set(attributes.amenity_ids || [])

    for (let i = 0, len = (attributes.domain_ids || []).length; i < len; ++i) {
      const id = attributes.domain_ids[i]
      villa.domains[id] = true
    }
    for (let i = 0, len = (attributes.taggings || []).length; i < len; ++i) {
      const { tag_id, amount } = attributes.taggings[i],
            tag = Tag.byID(tag_id)
      villa.taggings[tag.category_id][tag.id] = amount
    }
    for (let i = 0, len = (attributes.descriptions || []).length; i < len; ++i) {
      const { id, category_id, key, de, en } = attributes.descriptions[i],
            cat = Category.byID(category_id),
            desc = new Description(id, category_id, key, cat.descriptions[key].label, de, en)
      CACHE.set(Description, id, desc)
      cat.addDescription(desc)
      villa.addDescription(desc)
    }
    for (let i = 0, len = (attributes.areas || []).length; i < len; ++i) {
      const { id, category_id, subtype, taggings, beds_count } = attributes.areas[i],
            area = new Area(id, category_id, subtype, beds_count)
      taggings.forEach(t => {
        area.taggings[t.tag_id] = t.amount
      })
      villa.addArea(area)
    }

    villa.cc_fee_usd = attributes.cc_fee_usd
    if (attributes.villa_price_eur) {
      villa.villa_price_eur = new VillaPrice(attributes.villa_price_eur)
    }
    if (attributes.villa_price_usd) {
      villa.villa_price_usd = new VillaPrice(attributes.villa_price_usd)
    }
    if (!attributes.villa_price_eur && !attributes.villa_price_usd) {
      // add dummy prices
      villa.villa_price_eur = new VillaPrice({ currency: "EUR" })
    }
    for (let i = 0, len = (attributes.holiday_discounts || []).length; i < len; ++i) {
      const { id, description, percent, days_before, days_after } = attributes.holiday_discounts[i],
            hd = new HolidayDiscount(id, description, percent, days_before, days_after)
      if (description === "christmas") {
        villa.holiday_discounts.christmas = hd
      } else if (description === "easter") {
        villa.holiday_discounts.easter = hd
      } else {
        throw new Error(`unexpected holiday discount: ${hd.description}`)
      }
    }
    for (let i = 0, len = (attributes.calendars || []).length; i < len; ++i) {
      const { id, url, name } = attributes.calendars[i],
            cal = new Calendar(id, url, name)
      villa.calendars.push(cal)
    }
    if (attributes.boat) {
      const { inclusion, exclusive_boat_id, optional_boat_ids } = attributes.boat
      villa.boat.inclusion = inclusion || "none"
      villa.boat.exclusive_id = exclusive_boat_id || null
      villa.boat.optional_ids = optional_boat_ids || []
    }
    return villa
  }

  constructor(id = null) {
    this.id = id // null | Number < 0 == new record
    this.remoteErrors = {}

    // basic properties
    this.name = null
    this.active = false
    this.buyable = false
    this.manager_id = null
    this.owner_id = null
    this.safe_code = null
    this.phone = null
    this.living_area = null
    this.pool_orientation = null
    this.minimum_booking_nights = 7
    this.minimum_people = 2

    // address-related
    this.street = null
    this.postal_code = null
    this.locality = null
    this.region = null
    this.country = null
    this.latitude = null
    this.longitude = null

    this.additional_properties = {}
    this.booking_pal_product = null

    // known domains (none selected)
    this.domains = Domain.all().reduce((domains, domain) => {
      domains[domain.id] = false
      return domains
    }, {})

    // set amount=0 for every known tag in every known (villa) category
    this.taggings = Category.all().reduce((taggings, category) => {
      taggings[category.id] = category.tag_ids.reduce((tags, tid) => {
        tags[tid] = 0
        return tags
      }, {})
      return taggings
    }, {})

    // this.areas[category_id][i] = instanceof Area
    this.areas = Category.all().reduce((areas, cat) => {
      if (cat.multiple_types) {
        areas[cat.id] = []
      }
      return areas
    }, {})

    // this.descriptions[key] = instanceof Description
    this.descriptions = Category.all().reduce((descs, cat) => {
      Object.values(cat.descriptions).forEach(desc => {
        const { key, label, de, en } = desc
        descs[key] = new Description(null, cat.id, key, label, de, en)
      })
      return descs
    }, {})

    this.villa_price_eur = null
    this.villa_price_usd = null
    this.cc_fee_usd = 0 // percentage

    this.holiday_discounts = {
      christmas: null,
      easter:    null,
    }

    this.calendars = []

    this.boat = new AssignableBoat()
  }

  get newRecord() {
    return !this.id || this.id <= 0
  }

  set errors(val) {
    this.remoteErrors = new Errors(val)
  }

  get errors() {
    return this.remoteErrors
  }

  get manager() {
    return Contact.byID(this.manager_id)
  }

  set manager(val) {
    this.manager_id = val.id
  }

  get owner() {
    return Contact.byID(this.owner_id)
  }

  set owner(val) {
    this.owner_id = val.id
  }

  get bedroomCount() {
    const cat = Category.byName("bedrooms")
    return cat ? this.areas[cat.id].length : 0
  }

  get bedCount() {
    const cat = Category.byName("bedrooms")
    return cat
      ? this.areas[cat.id].reduce((count, area) => {
        return count + (area._destroy ? 0 : area.beds_count)
      }, 0)
      : 0
  }

  get domain_ids() {
    return Object.entries(this.domains)
      .filter(d => d[1])
      .map(d => Number(d[0]))
  }

  set domain_ids(val) {
    Object.keys(this.domains).forEach(id => {
      this.domains[id] = false
    })
    Array.from(val).forEach(id => {
      this.domains[id] = true
    })
  }

  get sections() {
    return Category.all().sort((a, b) => {
      const ai = SECTION_ORDER.indexOf(a.name),
            bi = SECTION_ORDER.indexOf(b.name)
      if (ai === bi) {
        return a.label.localeCompare(b.label)
      }
      return ai - bi
    }).map(cat => {
      return {
        category:     cat,
        taggings:     this.taggings[cat.id],
        descriptions: Object.keys(cat.descriptions).map(key => this.descriptions[key]),
        areas:        this.areas[cat.id],
      }
    })
  }

  addArea(area, categoryId) {
    if (!area) {
      area = new Area(null, categoryId, "")
    }

    this.areas[area.category_id].push(area)
  }

  addDescription(desc) {
    this.descriptions[desc.key] = desc
  }

  addCalendar() {
    this.calendars.push(new Calendar())
  }

  toJSON() {
    return VILLA_PRIMITIVES.reduce((o, attr) => {
      o[attr] = this[attr]
      return o
    }, {
      id:           this.id,
      domain_ids:   this.domain_ids,
      descriptions: Object.values(this.descriptions),

      areas: Object.values(this.areas).reduce((areas, list) => {
        return areas.concat(list)
      }, []),

      taggings: Object.values(this.taggings).reduce((taggings, val) => {
        return taggings.concat(denormalizeTagList(val))
      }, []),

      holiday_discounts: [].concat(this.holiday_discounts.christmas, this.holiday_discounts.easter),
      villa_price_eur:   this.villa_price_eur,
      villa_price_usd:   this.villa_price_usd,

      calendars: this.calendars,
      boat:      this.boat,
    })
  }
}

const SECTION_ORDER = Object.freeze({
  categoryNames: [
    "highlights",
    "bedrooms",
    "bathrooms",
    "kitchen",
    "lavatory",
    "livingroom",
    "entertainment",
    "outdoor",
    "location",
    "theme",
    "accessoires",
    "boat",
    "gym",
  ],
  indexOf(name) {
    const i = this.categoryNames.indexOf(name)
    return i < 0 ? this.categoryNames.length : i
  },
})
