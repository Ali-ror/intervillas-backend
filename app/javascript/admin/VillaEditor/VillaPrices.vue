<template>
  <form action="#" @submit.prevent>
    <fieldset class="form-horizontal">
      <legend>Personen-Preise</legend>

      <div class="form-group">
        <label for="villa_price_mode" class="control-label col-sm-3">
          Abrechnungsmodus
        </label>
        <div class="col-sm-9 col-md-6 col-lg-3">
          <select
              id="villa_price_mode"
              v-model="pricingMode"
              class="form-control"
          >
            <option value="nightly">
              pro Person/pro Nacht
            </option>
            <option value="weekly">
              Wochenpreis
            </option>
          </select>

          <span class="help-block">
            Häuser können entweder zu einem festen Wochenpreis vermietet werden,
            oder mit einem Grundpreis pro Übernachtung.
          </span>
        </div>
      </div>

      <div class="form-group">
        <label class="control-label col-sm-3">
          Währungen
        </label>
        <div class="col-sm-9 col-md-6">
          <div class="radio list-group">
            <div class="list-group-item">
              <label>
                <input
                    v-model="currencyMode"
                    type="radio"
                    value="only-eur"
                >
                <u>EUR</u> (autom. Umrechnung für USD)
                <span class="help-block mb-0">
                  Die Preiseingabe erfolgt in Euro, und US-Dollar-Preise werden automatisch
                  im Hintergrund umgerechnet. Kunden können über die Währungsauswahl
                  zwischen Euro und Dollar umschalten.
                </span>
              </label>
            </div>
            <div class="list-group-item">
              <label>
                <input
                    v-model="currencyMode"
                    type="radio"
                    value="all"
                >
                <u>EUR</u> und <u>USD</u>
                <span class="help-block mb-0">
                  Es werden für Euro und US-Dollar separate Preise eingegeben, eine
                  automatische Umrechnung passiert nicht. Dem Kunden werden die Preise
                  gemäß seiner Auswahl angezeigt.
                </span>
              </label>
            </div>
            <div class="list-group-item">
              <label>
                <input
                    v-model="currencyMode"
                    type="radio"
                    value="only-usd"
                >
                <u>USD</u> (exklusiv)
                <span class="help-block mb-0">
                  Es werden US-Dollar-Preise eingegeben und das Haus zeigt ausschließlich
                  diese Preise an. Die Währungsauswahl des Kunden spielt keine Rolle
                  (d.h. auch wenn dieser Euro gewählt hat, wird das Haus mit Dollar-Preisen
                  angezeigt).
                </span>
              </label>
            </div>
          </div>
        </div>
      </div>

      <div class="form-group">
        <div class="col-sm-9 col-md-6 col-sm-offset-3">
          <div class="row text-muted text-center small">
            <div v-if="['all', 'only-eur'].includes(currencyMode)" class="col-sm-4">
              <div class="border-bottom border-light">
                EUR-Preise
              </div>
            </div>
            <div v-if="['all', 'only-usd'].includes(currencyMode)" class="col-sm-8">
              <div class="border-bottom border-light">
                USD-Preise
              </div>
              <div class="row">
                <em class="col-sm-6">
                  ohne KK-Gebühr, wird ggü. dem Eigentümer abgerechnet
                </em>
                <em class="col-sm-6">
                  einschließlich {{ ccFeePercent }} KK-Gebühr, wird dem Mieter angezeigt
                </em>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
          v-for="(title, cat) in persPrices"
          :key="cat"
          class="form-group"
          :class="formGroupClass('villa_price', cat, 'value')"
      >
        <label
            class="control-label col-sm-3"
            :for="`villa_villa_price_${cat}`"
        >
          {{ title }}

          <ToggleSwitch
              v-if="['children_under_6', 'children_under_12'].includes(cat)"
              :active="hasChildPrices(cat)"
              :name="title"
              @click="setChildPrices(cat, $event)"
          />
        </label>
        <div class="col-sm-9 col-md-6">
          <div class="row">
            <div
                v-for="price in eachActiveCurrency(cat)"
                :key="price.key"
                :class="`col-sm-${price.currency === 'EUR' ? 4 : 8 }`"
            >
              <CCFeePriceInput
                  :id="price.key"
                  :key="price.key"
                  v-model.number="price.value.$model"
                  :cc-percent="villa.cc_fee_usd"
                  :title="title"
                  :currency="price.currency"
                  :readonly="!hasChildPrices(cat)"
              />

              <div
                  v-for="(err, i) in price.errors"
                  :key="i"
                  class="help-block"
                  v-text="err"
              />
            </div>
          </div>
        </div>
      </div>

      <div v-if="pricingMode === 'nightly' && villa.minimum_people !== 2" class="form-group">
        <label class="control-label col-sm-3">Kinder</label>
        <div class="col-sm-9 col-md-6">
          <p class="form-control-static">
            <em class="text-muted">
              Bei diesem Haus ist eine Mindestpersonenzahl ({{ villa.minimum_people }})
              eingerichtet, bei der Kinderpreise nicht möglich sind.
            </em>
          </p>
        </div>
      </div>

      <div v-if="pricingMode === 'weekly'" class="form-group">
        <label class="control-label col-sm-3">
          Wochenpreis (für bis zu {{ villa.bedCount }} Personen)
        </label>

        <div class="col-sm-9 col-md-6">
          <div class="row">
            <div
                v-for="price in eachActiveCurrency('base_rate')"
                :key="price.key"
                :class="`col-sm-${price.currency === 'EUR' ? 4 : 8 }`"
            >
              <CCFeePriceInput
                  :id="`${price.key}_weekly`"
                  :key="`${price.key}_weekly`"
                  :cc-percent="villa.cc_fee_usd"
                  :value="price.value.$model * 7"
                  title="Wochenpreis"
                  :currency="price.currency"
                  readonly
              />
            </div>
          </div>
          <span class="help-block">
            Wochenpreis berechnet sich aus 7&thinsp;× Preis pro Übernachtung
          </span>
        </div>
      </div>
    </fieldset>

    <fieldset class="form-horizontal">
      <legend>Sonstige Preise</legend>

      <div
          v-for="(title, cat) in miscPrices"
          :key="cat"
          class="form-group"
          :class="formGroupClass('villa_price', cat, 'value')"
      >
        <label
            class="control-label col-sm-3"
            :for="`villa_villa_price_eur_${cat}`"
            v-text="title"
        />
        <div class="col-sm-9 col-md-6">
          <div class="row">
            <div
                v-for="price in eachActiveCurrency(cat)"
                :key="price.key"
                :class="`col-sm-${price.currency === 'EUR' ? 4 : 8 }`"
            >
              <CCFeePriceInput
                  :id="price.key"
                  :key="price.key"
                  v-model.number="price.value.$model"
                  :cc-percent="villa.cc_fee_usd"
                  :title="title"
                  :currency="price.currency"
              />

              <div
                  v-for="(err, i) in price.errors"
                  :key="i"
                  class="help-block"
                  v-text="err"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="form-group">
        <label for="villa_energy_cost_calculation" class="control-label col-sm-3">
          Vorgabe für Energiekostenberechnung
        </label>

        <div class="col-sm-9 col-md-6">
          <div class="radio list-group">
            <div class="list-group-item">
              <label>
                <input
                    v-model="$v.villa.energy_cost_calculation.$model"
                    type="radio"
                    value="defer"
                >
                In Angebot oder Abrechnung festlegen
                <span class="help-block mb-0">
                  Es wird keine Vorgabe gemacht. Die Berechnungsmethode für die
                  Energiekosten kann entweder beim Erstellen des Angebots festgelegt
                  werden, oder aber spätestens zum Zeitpunkt der Abrechnung.
                </span>
              </label>
            </div>
            <div class="list-group-item">
              <label>
                <input
                    v-model="$v.villa.energy_cost_calculation.$model"
                    type="radio"
                    value="usage"
                >
                nach Verbrauch
                <span class="help-block mb-0">
                  Die Abrechnung lässt ausschließlich die Eingaben für den Verbrauch
                  zu (also Zählerstände und Preis pro kWh).
                </span>
              </label>
            </div>
            <div class="list-group-item">
              <label>
                <input
                    v-model="$v.villa.energy_cost_calculation.$model"
                    type="radio"
                    value="flat"
                >
                Pauschale
                <span class="help-block mb-0">
                  Die Abrechnung lässt ausschließlich die Eingaben für einen Festpreis zu.
                </span>
              </label>
            </div>
            <div class="list-group-item">
              <label>
                <input
                    v-model="$v.villa.energy_cost_calculation.$model"
                    type="radio"
                    value="included"
                >
                im Mietpreis enthalten
                <span class="help-block mb-0">
                  Bei der Abrechnung ist keine Eingabe für Energiekosten vorgesehen.
                  Die entsprechende Klausel im Vertragstext ("Energiekosten werden
                  mit der Nebenkostenrückzahlung verrechnet") entfällt.
                </span>
              </label>
            </div>
          </div>
        </div>
      </div>
    </fieldset>

    <fieldset class="form-horizontal">
      <legend>Feiertagszuschläge</legend>

      <div class="row">
        <div
            v-for="([title, subtitle], cat) in holidays"
            :key="cat"
            class="col-sm-6 col-lg-4"
        >
          <DiscountPanel
              :key="cat"
              v-model="$v.villa.holiday_discounts[cat]"
              :title="title"
              :subtitle="subtitle"
              :id-prefix="`holiday_discounts_${cat}_`"
              @add="addHolidayDiscount(cat)"
          />
        </div>
      </div>
    </fieldset>

    <slot
        name="buttons"
        :payload-fn="buildPayload"
        :active="!wasClean"
    />
  </form>
</template>

<script>
import Utils from "../../intervillas-drp/utils"
import { VillaPrice, HolidayDiscount } from "./models"
import Common from "./common"
import DiscountPanel from "./prices/HolidayDiscount.vue"
import CCFeePriceInput from "./prices/CCFeePriceInput.vue"
import ToggleSwitch from "../ToggleSwitch.vue"
import { validationMixin } from "vuelidate"
import { decimal, greaterThan, integer, minValue, required } from "./validators"

export default {
  components: {
    DiscountPanel,
    CCFeePriceInput,
    ToggleSwitch,
  },

  mixins: [Common, validationMixin],

  data() {
    return {
      priceModeOverride: null, // user selection
      priceModeBackup:   { // backup of price values, in case user wants revert selection
        eur: {
          base_rate:         null,
          additional_adult:  null,
          children_under_6:  null,
          children_under_12: null,
        },
        usd: {
          base_rate:         null,
          additional_adult:  null,
          children_under_6:  null,
          children_under_12: null,
        },
      },
    }
  },

  validations() {
    const priceValidation = () => ({
      weekly_rate:       {},
      base_rate:         { value: { decimal, greaterThan: greaterThan(0) } },
      additional_adult:  { value: { decimal, minValue: minValue(0) } },
      children_under_12: { value: { decimal, minValue: minValue(0) } },
      children_under_6:  { value: { decimal, minValue: minValue(0) } },
      cleaning:          { value: { decimal, greaterThan: greaterThan(0) } },
      deposit:           { value: { decimal, greaterThan: greaterThan(0) } },
      _destroy:          {},
    })

    const holidayValidation = () => ({
      days_before: { required, integer, greaterThan: greaterThan(0) },
      days_after:  { required, integer, greaterThan: greaterThan(0) },
      percent:     { required, integer, minValue: minValue(0) },
      _destroy:    {},
    })

    const energyCalculation = value => ["defer", "usage", "flat", "included"].includes(value)

    return {
      villa: {
        villa_price_eur:   priceValidation(),
        villa_price_usd:   priceValidation(),
        holiday_discounts: {
          christmas: holidayValidation(),
          easter:    holidayValidation(),
        },
        energy_cost_calculation: { energyCalculation },
      },
    }
  },

  computed: {
    currencyMode: {
      /** @returns {"only-eur"|"only-usd"|"all"} */
      get() {
        const active = [this.villa.villa_price_eur, this.villa.villa_price_usd]
          .filter(p => p && !p._destroy)
          .map(p => p.currency.toLowerCase())

        if (active.length === 1) {
          return `only-${active[0]}`
        }
        return "all"
      },

      /** @param {"only-eur"|"only-usd"|"all"} val */
      set(val) {
        const activatePrices = (eur, usd) => {
          if (this.villa.villa_price_eur) {
            this.villa.villa_price_eur._destroy = !eur
          } else if (eur) {
            this.villa.villa_price_eur = new VillaPrice({ currency: "EUR" })
          }
          if (this.villa.villa_price_usd) {
            this.villa.villa_price_usd._destroy = !usd
          } else if (usd) {
            this.villa.villa_price_usd = new VillaPrice({ currency: "USD" })
          }
        }

        switch (val) {
        case "only-eur":
          activatePrices(true, false)
          break
        case "only-usd":
          activatePrices(false, true)
          break
        case "all":
          activatePrices(true, true)
          break
        default:
          throw new Error(`unexpected villa currency: ${val}`)
        }
      },
    },

    pricingMode: {
      /** @returns {"weekly"|"nightly"} */
      get() {
        if (this.priceModeOverride) {
          return this.priceModeOverride
        }

        const { villa_price_eur: eur, villa_price_usd: usd } = this.villa,
              prices = !eur || eur._destroy ? usd : eur,
              { additional_adult, children_under_6, children_under_12 } = prices,
              absent = ({ value }) => value === 0 || value == null

        if (absent(additional_adult) && absent(children_under_6) && absent(children_under_12)) {
          return "weekly"
        }
        return "nightly"
      },

      /** @param {"weekly"|"nightly"} val */
      set(val) {
        const backup = p => {
          if (this.villa.villa_price_eur) {
            this.$set(this.priceModeBackup.eur, p, this.villa.villa_price_eur[p].value)
          }
          if (this.villa.villa_price_usd) {
            this.$set(this.priceModeBackup.usd, p, this.villa.villa_price_usd[p].value)
          }
        }

        const restore = p => {
          if (this.villa.villa_price_eur) {
            this.villa.villa_price_eur[p].value = this.priceModeBackup.eur[p]
          }
          if (this.villa.villa_price_usd) {
            this.villa.villa_price_usd[p].value = this.priceModeBackup.usd[p]
          }
        }

        const zero = p => {
          if (p) {
            p.additional_adult.value = null
            p.children_under_6.value = null
            p.children_under_12.value = null
          }
        }

        switch (val) {
        case "nightly":
          backup("base_rate")
          this.priceModeOverride = val
          restore("additional_adult")
          restore("children_under_6")
          restore("children_under_12")
          break
        case "weekly":
          backup("additional_adult")
          backup("children_under_6")
          backup("children_under_12")
          this.priceModeOverride = val
          zero(this.villa.villa_price_eur)
          zero(this.villa.villa_price_usd)
          restore("base_rate")
          break
        default:
          throw new Error(`unexpected villa pricing mode: ${val}`)
        }
      },
    },

    persPrices() {
      switch (this.pricingMode) {
      case "nightly":
        if (this.villa.minimum_people === 2) {
          return {
            base_rate:         `Grundpreis für ${this.villa.minimum_people} Pers.`,
            additional_adult:  "weitere Person",
            children_under_12: "Kind bis 12 J.",
            children_under_6:  "Kind bis 6 J.",
          }
        }
        return {
          base_rate:        `Grundpreis für ${this.villa.minimum_people} Pers.`,
          additional_adult: "weitere Person",
        }

      case "weekly":
        return {
          base_rate: "pro Übernachtung",
        }
      default:
        return {}
      }
    },

    miscPrices() {
      return {
        deposit:  "Kaution",
        cleaning: "Reinigung",
      }
    },

    holidays() {
      return {
        christmas: ["Weihnachten", "25.+26. Dezember"],
        easter:    ["Ostern", "Ostersonntag"],
      }
    },

    ccFeePercent() {
      return `${this.villa.cc_fee_usd} %`
    },
  },

  methods: {
    eachActiveCurrency(cat) {
      const active = []

      if (["only-eur", "all"].includes(this.currencyMode)) {
        active.push({
          key:      `${cat}-eur`,
          currency: "EUR",
          value:    this.$v.villa.villa_price_eur[cat].value,
          errors:   this.errorsFor("villa_price_eur", cat, "value"),
        })
      }
      if (["only-usd", "all"].includes(this.currencyMode)) {
        active.push({
          key:      `${cat}-usd`,
          currency: "USD",
          value:    this.$v.villa.villa_price_usd[cat].value,
          errors:   this.errorsFor("villa_price_usd", cat, "value"),
        })
      }
      return active
    },

    hasChildPrices(cat) {
      if (!["children_under_6", "children_under_12"].includes(cat)) {
        return true
      }
      if (["only-eur", "all"].includes(this.currencyMode)) {
        if (Number.isFinite(this.$v.villa.villa_price_eur[cat].value.$model)) {
          return true
        }
      }
      if (["only-usd", "all"].includes(this.currencyMode)) {
        if (Number.isFinite(this.$v.villa.villa_price_usd[cat].value.$model)) {
          return true
        }
      }
      return false
    },

    setChildPrices(cat, active) {
      if (["only-eur", "all"].includes(this.currencyMode)) {
        this.$v.villa.villa_price_eur[cat].value.$model = active ? 0 : ""
      }
      if (["only-usd", "all"].includes(this.currencyMode)) {
        this.$v.villa.villa_price_usd[cat].value.$model = active ? 0 : ""
      }
    },

    addHolidayDiscount(cat) {
      const hd = new HolidayDiscount(null, cat, 0, 0, 0)
      this.$set(this.villa.holiday_discounts, cat, hd)
    },

    buildPayload() {
      const villa = Utils.dup(this.villa)
      return {
        holiday_discounts:       villa.holiday_discounts,
        villa_price_eur:         this.sanitizeAdditionalAdults(villa.villa_price_eur),
        villa_price_usd:         this.sanitizeAdditionalAdults(villa.villa_price_usd),
        energy_cost_calculation: villa.energy_cost_calculation,
      }
    },

    // People prices must not be null; for weekly pricing, they must be 0 instead.
    // See also support#674
    sanitizeAdditionalAdults(prices) {
      if (prices && this.pricingMode === "weekly") {
        prices.additional_adult = 0
        // prices.children_under_6 = 0
        // prices.children_under_12 = 0
      }
      return prices
    },
  },
}
</script>
