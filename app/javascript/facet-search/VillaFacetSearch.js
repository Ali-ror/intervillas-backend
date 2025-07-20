import Filter from "./filter"
import { Availability } from "./availability"
import { RangePicker, Caption } from "@digineo/date-range-picker"
import Utils from "../intervillas-drp/utils"
import { rangeSize, annotate } from "../intervillas-drp/special-dates"
import { CARDINAL_DIRECTIONS } from "../cardinal_directions"
import { format, setHours } from "date-fns"
import { makeDate, formatDate } from "../lib/DateFormatter"
import { translate } from "@digineo/vue-translate"

const doNotUpdate = Symbol("no update needed"),
      fallbackToDataset = Symbol("dataset fallback"),
      updateWhenPresent = (instance, prop, state, key, fallback = doNotUpdate) => {
        if (Object.prototype.hasOwnProperty.call(state, key)) {
          instance[prop] = state[key]
        } else if (fallback === doNotUpdate) {
          // do not update
        } else if (fallback === fallbackToDataset) {
          instance[prop] = instance.dataset.query[key]
        } else {
          instance[prop] = fallback
        }
      }

const minMax = (...list) => {
  const len = list.length

  // trivial cases
  switch (len) {
  case 0:
    return [null, null]
  case 1:
    return [list[0], list[0]]
  case 2:
    return list[0] > list[1] ? [list[1], list[0]] : [list[0], list[1]]
  }

  // len >= 3
  let min = Infinity,
      max = -Infinity
  for (let i = 0; i < len; ++i) {
    const e = list[i]
    if (e < min) {
      min = e
    }
    if (e > max) {
      max = e
    }
  }
  return [min, max]
}

/**
 * mkRange expands a range (given by start/end value) to an array.
 * @param {Number} min begin of range
 * @param {Number} max end of range
 */
const mkRange = (min, max) => {
  if (min === null || max === null) {
    return
  }

  const range = []
  for (let i = min; i <= max; ++i) {
    range.push(i)
  }
  return range
}

/**
 * Some Array.prototype.sort compare functions.
 */
const SortBy = Object.freeze({
  /**
   * Sorts an string-array alphabetically (case insensitive).
   * @param {string} a
   * @param {string} b
   * @return Number
   */
  alphabet: (a, b) => {
    const al = a.toLowerCase(),
          bl = b.toLowerCase()
    return al < bl ? -1 : (al > bl ? 1 : 0)
  },

  /**
   * Sorts a number-array.
   * @param {Number} a
   * @param {Number} b
   */
  number: (a, b) => a - b,

  /**
   * Constructs a comparator for an object-array, which sorts by the
   * given (string) attribute alphabetically.
   * @param {string} name Name of the attribute
   */
  attribute: name => (a, b) => SortBy.alphabet(a[name], b[name]),

  /**
   * Inverts a given compare function.
   * @param {function} cmp A compare function, like SortBy.number
   */
  inverse: cmp => (a, b) => -cmp(a, b),
})

export default {
  name: "VillaFacetSearch",

  components: {
    RangePicker,
  },

  data() {
    return {
      extraClasses: [], // siehe beforeMount

      peopleRange: [], // Anz. möglicher Personen
      roomRange:   [], // Anz. vorhandener Schlafzimmer

      startDate: null, // Anreise-Datum
      endDate:   null, // Abreise-Datum
      people:    null, // ausgewählte Anz. Personen
      rooms:     null, // ausgewählte Anz. Schlafzimmer

      offerFacets: true,
      showFacets:  false, // fährt Facetten-Bereich aus
      facetsData:  null, // Daten vom Server
      haveFacets:  Promise.reject(new Error("uninitialized")).catch(() => {}),

      orientations: CARDINAL_DIRECTIONS.reduce((acc, cur) => {
        acc[cur] = true
        return acc
      }, {}),

      locVillas:         {}, // VillaID → property location
      mapVillas:         {}, // VillaID → Array[TagID]
      mapTags:           {}, // TagID → Array[VillaID]
      tagState:          {}, // TagID → Availability, Facetten und deren Status
      availableVillaIDs: [], // Array[VillaID], Liste verfügbarer Villen aus Ergebnisliste (extern)
    }
  },

  computed: {
    /** peopleCollection returns an array wir numbers from peopleRange[0] to peopleRange[1] (both incl.) */
    peopleCollection() {
      return mkRange(this.peopleRange[0], this.peopleRange[1])
    },

    /** roomsCollection returns an array wir numbers from peopleRange[0] to peopleRange[1] (both incl.) */
    roomsCollection() {
      return mkRange(this.roomRange[0], this.roomRange[1])
    },

    /**
     * Computes the list of selected tag IDs.
     * @return Number[]
     */
    selectedTags() {
      return Object.keys(this.tagState).reduce((list, key) => {
        const id = parseInt(key, 10)
        if (this.tagState[id] === Availability.SELECTED) {
          list.push(id)
        }
        return list
      }, [])
    },

    /**
     * Computes the visibility state for each villa, given the selected
     * tags and property locations.
     * @return Object (VillaID → Availability)
     */
    villas() {
      const result = {},
            selectedTags = this.selectedTags,
            map = this.mapVillas,
            villaIDs = Object.keys(map)

      for (let i = 0, len = villaIDs.length; i < len; ++i) {
        const id = parseInt(villaIDs[i], 10), // Object.keys returns strings
              villaTags = map[id],
              villaLoc = this.locVillas[id]

        const availByTag = selectedTags.length === 0 || selectedTags.every(t => villaTags.includes(t)),
              availByLoc = this.orientations[villaLoc]

        if (availByTag && availByLoc) {
          result[id] = Availability.AVAILABLE
        } else {
          result[id] = Availability.UNAVAILABLE
        }
      }
      return result
    },

    availableVillaIDsByTag() {
      const result = {},
            tagIDs = Object.keys(this.mapTags),
            villas = Object.keys(this.villas)
              .map(id => parseInt(id, 10))
              .filter(id => this.villas[id] !== Availability.UNAVAILABLE)
              .filter(id => this.availableVillaIDs.includes(id))

      for (let i = 0, len = tagIDs.length; i < len; ++i) {
        const id = parseInt(tagIDs[i], 10),
              collection = this.mapTags[id]
        result[id] = collection.filter(vid => villas.includes(vid))
      }
      return result
    },

    rangePickerBinding() {
      return {
        startDate: this.startDate ? setHours(makeDate(this.startDate), 16) : null,
        endDate:   this.endDate ? setHours(makeDate(this.endDate), 8) : null,
        minDate:   new Date(),
        canDelete: true,
        captions:  [new Caption("high-season", "drp.caption.high_season")],
        rangeSize: date => rangeSize(date),
        annotate:  annotate,
      }
    },
  },

  watch: {
    /**
     * facetsData is updated when the AJAX promise resolves (see method
     * toggleFacets). When this happens, we need to build different
     * indices, mainly bidirectional maps between Tag and Villa IDs.
     */
    facetsData({ categories, villas }) {
      this.mapVillas = {}
      this.mapTags = {}
      this.locVillas = {}

      const byName = SortBy.attribute("name")

      categories.sort((a, b) => {
        // sort top cat to front
        if (a.top) {
          return -1
        }
        if (b.top) {
          return 1
        }
        // else sort by name
        return byName(a, b)
      })

      for (let i = 0, ilen = categories.length; i < ilen; ++i) {
        const cat = categories[i]
        cat.tags.sort(byName)

        for (let j = 0, jlen = cat.tags.length; j < jlen; ++j) {
          const tag = cat.tags[j]
          this.mapTags[tag.id] = []
          if (!this.tagState[tag.id]) {
            this.$set(this.tagState, tag.id, Availability.AVAILABLE)
          }
        }
      }
      for (let i = 0, ilen = villas.length; i < ilen; ++i) {
        const villa = villas[i]
        this.$set(this.mapVillas, villa.id, villa.tags.slice(0))
        this.$set(this.locVillas, villa.id, villa.loc)

        for (let j = 0, jlen = villa.tags.length; j < jlen; ++j) {
          const tag = villa.tags[j]
          this.mapTags[tag].push(villa.id)
        }
      }

      this.$emit("ready", this._getFilterData())
    },
  },

  methods: {
    formatDate,
    translate,
    t: (key, opts = {}) => translate(key, { ...opts, scope: "facets" }),

    toggleOrientation(loc) {
      this.orientations[loc] = !this.orientations[loc]
      this.applyFilter()
    },

    orientationToggleClasses(loc) {
      const selected = this.orientations[loc]
      return {
        "fa-toggle-on":  selected,
        "fa-toggle-off": !selected,
      }
    },

    /**
     * (De-)Selects a tag, depending on the previous state.
     * @param {Number} tagID ID of the tag
     */
    toggleTag(tagID) {
      switch (this.tagState[tagID]) {
      case Availability.SELECTED:
        this.$set(this.tagState, tagID, Availability.AVAILABLE)
        this.applyFilter()
        break
      case Availability.AVAILABLE:
        this.$set(this.tagState, tagID, Availability.SELECTED)
        this.applyFilter()
        break
      }
    },

    /**
     * Checks whether a given tag is selected
     * @param {Number} tagID ID of the tag
     * @returns Boolean
     */
    isTagSelected(tagID) {
      return this.tagState[tagID] === Availability.SELECTED
    },

    /**
     * Checks whether a given tag is not available for selection
     * @param {Number} tagID ID of the tag
     * @returns Boolean
     */
    isTagDisabled(tagID) {
      return this.tagState[tagID] === Availability.UNAVAILABLE || this.countVillasWithTag(tagID) <= 0
    },

    /**
     * Checks whether a given tag is available for selection
     * @param {Number} tagID ID of the tag
     * @returns Boolean
     */
    isTagAvailable(tagID) {
      return this.tagState[tagID] === Availability.AVAILABLE && this.countVillasWithTag(tagID) > 0
    },

    countVillasWithTag(tagID) {
      return this.availableVillaIDsByTag[tagID].length
    },

    tagDisplayClasses(tagID) {
      return {
        available:   this.isTagAvailable(tagID),
        unavailable: this.isTagDisabled(tagID),
        selected:    this.isTagSelected(tagID),
      }
    },

    tagToggleClasses(tagID) {
      const selected = this.isTagSelected(tagID)
      return {
        "text-muted":    this.isTagDisabled(tagID),
        "fa-toggle-on":  selected,
        "fa-toggle-off": !selected,
      }
    },

    /**
     * Click-handler for "show/hide more filters".
     *
     * Requests facet data from server on the first click and toggles
     * display of filter panel afterwards.
     *
     * Gotcha: If the request takes longer, and the user clicks multiple
     * times on the button, only request the facet data once.
     */
    toggleFacets() {
      this.haveFacets.then(() => {
        this.showFacets = !this.showFacets
      }).catch(() => {
        this.showFacets = false
      })
    },

    removeAndToggleFacets() {
      const tagIDs = Object.keys(this.tagState)
      for (let i = 0, len = tagIDs.length; i < len; ++i) {
        const id = parseInt(tagIDs[i], 10)
        if (this.tagState[id] === Availability.SELECTED) {
          this.$set(this.tagState, id, Availability.AVAILABLE)
        }
      }

      Object.keys(this.orientations).forEach(loc => {
        this.$set(this.orientations, loc, true)
      })
      this.showFacets = false
      this.applyFilter()
    },

    /**
     * User has clicked on "apply filter" button.
     */
    applyFilter(force = false) {
      if (this.offerFacets || force) {
        this.$emit("changeFilter", this._getFilterData())
      }
    },

    updateAvailableVillas(villaIDs) {
      this.availableVillaIDs.splice(0)
      this.availableVillaIDs.push(...villaIDs)
      this.availableVillaIDs.sort(SortBy.number)
    },

    _getFilterData() {
      const activeVillaIDs = [],
            villaIDs = Object.keys(this.villas),
            len = villaIDs.length
      for (let i = 0; i < len; ++i) {
        const id = parseInt(villaIDs[i], 10)
        if (this.villas[id] === Availability.AVAILABLE) {
          activeVillaIDs.push(id)
        }
      }

      const locations = Object.keys(this.orientations).reduce((acc, loc) => {
        if (this.orientations[loc]) {
          acc.push(loc)
        }
        return acc
      }, [])

      return new Filter(activeVillaIDs, {
        startDate: this.startDate,
        endDate:   this.endDate,
        numPeople: this.people,
        numRooms:  this.rooms,
        tagIDs:    this.selectedTags,
        locations,
      })
    },

    _setFilterData(data) {
      updateWhenPresent(this, "startDate", data, "start_date", fallbackToDataset)
      updateWhenPresent(this, "endDate", data, "end_date", fallbackToDataset)
      updateWhenPresent(this, "people", data, "people", 2)
      updateWhenPresent(this, "rooms", data, "rooms", 2)

      this.$children.forEach(child => {
        if (typeof child.updateStartEndDates === "function") {
          child.updateStartEndDates(this.startDate, this.endDate)
        }
      })

      Object.keys(this.tagState).forEach(key => {
        const id = parseInt(key, 10)
        this.$set(this.tagState, id, Availability.AVAILABLE)
      })

      let showFacets = false
      if (data.tags && data.tags.length) {
        data.tags.split(",").forEach(tag => {
          const id = parseInt(tag, 10)
          this.$set(this.tagState, id, Availability.SELECTED)
        })
        showFacets = true
      }
      if (data.locations && data.locations.length) {
        data.locations.split(",").forEach(loc => {
          this.$set(this.orientations, loc, true)
        })
        showFacets = true
      }

      this.showFacets = showFacets

      this.$emit("statePopped", this._getFilterData())
      this.$forceUpdate()
    },

    /**
     * User has changed the travel period.
     * @param {Date | number} start Date of arrival
     * @param {Date | number} end Date of departure
     */
    drpChange([start, end]) {
      this.startDate = format(start, "yyyy-MM-dd")
      this.endDate = format(end, "yyyy-MM-dd")
      this.applyFilter(true)
    },
  },

  /** Extract data-attribute and prepare instance. */
  beforeMount() {
    this.extraClasses = Array.from(this.$el.classList)

    const config = JSON.parse(this.$el.dataset["config"])
    this.dataset = config
    let tmp

    this.offerFacets = config.facets

    if (tmp = config.constraints) {
      this.peopleRange = minMax(...tmp.people)
      this.roomRange = minMax(...tmp.rooms)
    }
    if (tmp = config.urls) {
      this.haveFacets = Utils.fetchJSON(tmp.facets).then(data => {
        this.facetsData = data
      })
    }
    if (tmp = config.query) {
      this.startDate = tmp.start_date
      this.endDate = tmp.end_date
      this.people = tmp.people
      this.rooms = tmp.rooms

      let toggleFacets = false
      for (let i = 0, len = tmp.tags.length; i < len; ++i) {
        const id = tmp.tags[i]
        this.$set(this.tagState, id, Availability.SELECTED)
        toggleFacets = true
      }
      if (tmp.locations.length > 0) {
        CARDINAL_DIRECTIONS.forEach(loc => {
          const hasLoc = tmp.locations.includes(loc)
          this.$set(this.orientations, loc, hasLoc)
        })
        toggleFacets = true
      }
      if (toggleFacets) {
        this.toggleFacets()
      }
    }
  },
}
