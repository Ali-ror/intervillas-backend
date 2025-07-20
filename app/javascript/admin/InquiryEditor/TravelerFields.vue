<template>
  <tr>
    <template v-if="removed">
      <td colspan="5" class="text-muted">
        <s v-if="value.first_name || value.last_name">
          {{ value.first_name }} {{ value.last_name }}
        </s>
        <s v-else>
          <em>?</em>
        </s>
      </td>
      <td>
        <button
            type="button"
            class="btn btn-default btn-sm"
            :title="t('keep')"
            @click="restoreTraveler(traveler_id)"
        >
          <i class="fa fa-undo fa-lg" />
        </button>
      </td>
    </template>

    <template v-else>
      <td>
        <ErrorWrapper :errors="$v.first_name">
          <input
              :id="`traveler-first_name-${traveler_id}`"
              v-model.trim="firstName"
              class="form-control input-sm"
              :placeholder="t('first_name')"
              type="text"
              @change="emitTraveler()"
          >
        </ErrorWrapper>
      </td>

      <td>
        <ErrorWrapper :errors="$v.last_name">
          <input
              :id="`traveler-last_name-${traveler_id}`"
              v-model.trim="lastName"
              class="form-control input-sm"
              :placeholder="t('last_name')"
              type="text"
              @change="emitTraveler()"
          >
        </ErrorWrapper>
      </td>

      <td>
        <select
            v-if="hasPriceCategories"
            :id="`traveler-price_category-${traveler_id}`"
            v-model="price_category"
            class="form-control input-sm"
            :placeholder="t('category')"
            @change="emitTraveler(); $emit('changed:price-relevant')"
        >
          <option
              v-for="(pval, i) in priceCategories"
              :key="i"
              :value="pval"
              v-text="priceCategoryLabels[pval]"
          />
        </select>

        <abbr
            v-else
            class="d-block text-center text-muted"
            :title="t('category_not_available.title')"
            v-text="t('category_not_available.abbr')"
        />
      </td>

      <td>
        <ErrorWrapper :errors="$v.born_on">
          <SinglePicker
              v-if="born_on"
              :id="`traveler-born_on-${traveler_id}`"
              ref="born_on"
              :can-delete="true"
              :start-date="born_on_moment"
              :start-date-input-name="false"
              :max-date="start_date_moment"
              @change="setTravelerDates($event)"
          >
            <template #display="display">
              <div class="input-group input-group-sm">
                <input
                    v-if="display.start"
                    :value="formatDate(display.start)"
                    class="form-control input-sm"
                    :placeholder="t('born_on')"
                    readonly
                    type="text"
                >
                <input
                    v-else
                    class="form-control input-sm"
                    :placeholder="t('born_on')"
                    readonly
                    type="text"
                    :value="t('born_on')"
                >
                <span
                    v-if="display.start"
                    class="input-group-addon"
                    :title="t('age_on_arrival')"
                    v-text="t('age', { n: age(display.start) })"
                />
              </div>
            </template>
          </SinglePicker>
          <input
              v-else
              type="text"
              class="form-control input-sm"
              readonly
              @click="openBornOnPicker()"
          >
        </ErrorWrapper>
      </td>

      <td>
        <ErrorWrapper :errors="$v.start_date">
          <VillaInquiryPicker
              :id="`traveler-start_date-${traveler_id}`"
              :end-date.sync="end_date_moment"
              :inquiry-id="inquiryId"
              :start-date.sync="start_date_moment"
              :villa-id="villaId"
              size="sm"
              @reload:unavailable="setUnavailable"
              @change="$emit('changed:price-relevant')"
          />
        </ErrorWrapper>
      </td>

      <td>
        <button
            class="btn btn-warning btn-sm"
            :title="t('remove')"
            type="button"
            @click="removeTraveler(traveler_id)"
        >
          <i class="fa fa-trash fa-lg" />
        </button>
      </td>
    </template>
  </tr>
</template>

<script>
import VillaInquiryPicker from "./VillaInquiryPicker.vue"
import ErrorWrapper from "./ErrorWrapper.vue"
import { SinglePicker } from "@digineo/date-range-picker"
import { helpers, requiredUnless } from "vuelidate/lib/validators"
import { validationMixin } from "vuelidate"
import Collection from "@digineo/date-range-picker/pickable/collection"
import { makeDate, formatDate } from "../../lib/DateFormatter"
import { format, isLeapYear } from "date-fns"

import { translate } from "@digineo/vue-translate"
const t = (key, opts = {}) => translate(key, { ...opts, scope: "inquiry_editor.traveler" })

/**
 * Mapping of price category name to max age.
 *
 * Keys are sorted in ascending order of max age.
 *
 * Note: These are all known price categories, however some cagetories
 * might not be available for the selected villa.
 */
const PRICE_CATEGORIES = Object.freeze({
  children_under_6:  6,
  children_under_12: 12,
  adults:            Infinity, // last element MUST be infinity
})

function mustNotBeOccupied() {
  return !this.isOccupied()
}

function age(born, ref) {
  if (!ref) {
    ref = new Date()
  }

  // split dates into parts
  const sy = ref.getFullYear(),
        sm = ref.getMonth(),
        sd = ref.getDate()
  const by = born.getFullYear(),
        bm = born.getMonth(),
        bd = born.getDate()

  // age = diff(years) - (1 if day-of-year(ref) < day-of-year(born_on))
  return (sy - by) - (sm < bm || (sm === bm && sd < bd) ? 1 : 0)
}

class Traveler {
  /**
   * @param {Date | number} start_date
   * @param {Date | number} [born_on]
   */
  constructor(start_date, born_on, categories) {
    this.start_date = makeDate(start_date)
    this.born_on = born_on ? makeDate(born_on) : null
    this.categories = categories
  }

  age(ref) {
    if (!this.born_on) {
      return
    }
    return age(this.born_on, ref)
  }

  hasBirthday(ref) {
    if (!this.born_on) {
      return false
    }

    // JS month indices
    const feb = 1, march = 2

    // check if start date falls on birthday (with special case for people born on Feb 29)
    const rm = ref.getMonth(),
          rd = ref.getDate(),
          bm = this.born_on.getMonth(),
          bd = this.born_on.getDate()
    if (!isLeapYear(this.start_date) && bd === 29 && bm === feb) {
      return rd === 1 && rm === march
    }
    return bd === rd && bm === rm
  }

  // keep in sync with app/models/traveler.rb, price_category_by_age()
  get category() {
    const age = this.age(this.start_date),
          bday = this.hasBirthday(this.start_date)

    return Object.keys(PRICE_CATEGORIES).find(cat => {
      const maxAge = PRICE_CATEGORIES[cat]

      // return (isYounger || hasBirthday) && validCategory
      return (age < maxAge || (age === maxAge && bday)) && this.categories.includes(cat)
    })
  }
}

function mustMatchCategory(categories) {
  return function(value) {
    const empty = !helpers.req(value)
    if (empty) {
      return true
    }

    const t = new Traveler(this.start_date_moment, this.born_on_moment, categories)
    return t.category === this.price_category
  }
}

export default {
  name: "TravelerFields",

  components: {
    VillaInquiryPicker,
    ErrorWrapper,
    SinglePicker,
  },

  mixins: [validationMixin],

  props: {
    value:           { type: Object, required: true },
    inquiryId:       { type: [String, Number], default: null },
    villaId:         { type: [String, Number], required: true },
    nameRequired:    { type: Boolean, default: true },
    priceCategories: { type: Array, default: () => ([]) },
  },

  data() {
    return {
      first_name:     this.value.first_name,
      last_name:      this.value.last_name,
      price_category: this.value.price_category,
      born_on:        this.value.born_on,
      start_date:     this.value.start_date,
      end_date:       this.value.end_date,
      removed:        this.value.removed,
      unavailable:    [],

      // NOTE: cannot move reduce() into a module level constant, as t()
      // might not be initialized yet
      priceCategoryLabels: Object.keys(PRICE_CATEGORIES).reduce((labels, cat) => {
        labels[cat] = t(`categories.${cat}`)
        return labels
      }, {}),
    }
  },

  validations() {
    const validations = {
      start_date: {
        required: requiredUnless("removed"),
        mustNotBeOccupied,
      },
      end_date: {
        required: requiredUnless("removed"),
      },
    }
    if (this.hasPriceCategories) {
      validations.born_on = {
        mustMatchCategory: mustMatchCategory(this.priceCategories),
      }
    }
    if (this.nameRequired) {
      validations.first_name = {
        required: requiredUnless("removed"),
      }
      validations.last_name = {
        required: requiredUnless("removed"),
      }
    }
    return validations
  },

  computed: {
    firstName: {
      get() {
        return this.first_name
      },
      set(inFirstName) {
        if (this.$v.first_name) {
          this.$v.first_name.$model = inFirstName
        } else {
          this.first_name = inFirstName
        }
      },
    },

    lastName: {
      get() {
        return this.last_name
      },
      set(inLastName) {
        if (this.$v.last_name) {
          this.$v.last_name.$model = inLastName
        } else {
          this.last_name = inLastName
        }
      },
    },

    traveler_id() {
      return this.value.id
    },

    born_on_moment() {
      return this.born_on ? makeDate(this.born_on) : null
    },

    start_date_moment: {
      get() {
        return makeDate(this.start_date)
      },
      set(value) {
        this.$v.start_date.$model = value
        this.$v.start_date.$touch()
        this.emitTraveler()
      },
    },

    end_date_moment: {
      get() {
        return makeDate(this.end_date)
      },
      set(value) {
        this.$v.end_date.$model = value
        this.$v.end_date.$touch()
        this.emitTraveler()
      },
    },

    days() {
      return new Collection(this.unavailable, this.start_date_moment, this.end_date_moment)
        .sliceDays(this.start_date_moment, this.end_date_moment)
    },

    hasPriceCategories() {
      return this.priceCategories && this.priceCategories.length > 0
    },
  },

  watch: {
    villaId: "touchAndEmit",
    value:   {
      deep: true,
      handler(newValue) {
        this.first_name = newValue.first_name
        this.last_name = newValue.last_name
        this.price_category = newValue.price_category
        this.born_on = newValue.born_on
        this.start_date = newValue.start_date
        this.end_date = newValue.end_date
        this.removed = newValue.removed
      },
    },
  },

  mounted() {
    this.touchAndEmit()
  },

  methods: {
    formatDate,
    translate,
    t,

    age(born) {
      return born
        ? age(makeDate(born), this.start_date_moment)
        : ""
    },

    setUnavailable(event) {
      this.unavailable = event
    },

    openBornOnPicker() {
      this.born_on = new Date()
      setTimeout(() => this.$refs.born_on.toggle(), 100)
    },

    touchAndEmit() {
      this.$v.$touch()
      // Validations auf parent triggern
      setTimeout(() => this.emitTraveler(), 500)
    },

    isOccupied() {
      for (let day of this.days) {
        if (day.options.blocked) {
          return true
        }
      }
    },

    setTravelerDates(dates) {
      this.born_on = format(dates[0], "yyyy-MM-dd")
      this.$v.$touch()
      this.emitTraveler()
    },

    removeTraveler(id) {
      // this.removed = true
      // this.$v.$touch()
      this.$emit("remove", id)
      this.$emit("changed:price-relevant")
    },

    restoreTraveler(id) {
      this.removed = false
      this.$emit("changed:price-relevant")
      this.$emit("restore", id)
    },

    emitTraveler() {
      const traveler = {
        id:             this.value.id,
        first_name:     this.first_name,
        last_name:      this.last_name,
        price_category: this.price_category,
        born_on:        this.born_on,
        start_date:     this.start_date,
        end_date:       this.end_date,
        isValid:        !this.$v.$anyError,
      }
      this.$emit("input", traveler)
    },
  },
}
</script>

<style scoped lang="scss">
  select {
    min-width: 110px;
  }
</style>
