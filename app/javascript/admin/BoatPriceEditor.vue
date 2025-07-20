<template>
  <form
      class="prices mb-5"
      :class="{ 'inhibit-interaction': loading || saving }"
      @submit.prevent="onSubmit"
  >
    <h2>Preise und Aufschläge</h2>

    <div class="fields gap-gutter">
      <div>
        <fieldset>
          <legend>Tagespreise</legend>

          <table class="table table-striped table-condensed">
            <thead>
              <tr>
                <th rowspan="2">
                  Buchungstage
                </th>
                <th colspan="2">
                  Preis pro Tag
                </th>
              </tr>
              <tr>
                <th>EUR</th>
                <th>USD</th>
              </tr>
            </thead>

            <tbody v-if="daily && daily.length">
              <PriceRow
                  v-for="(p, i) in daily"
                  :key="`${p.amount}d`"
                  v-model="daily[i]"
                  :exchange-rate="exchangeRate"
                  @keep="keepDailyPrice(i)"
                  @destroy="destroyDailyPrice(i)"
              />
            </tbody>
            <tbody v-else>
              <tr>
                <td colspan="4">
                  <em class="text-muted">Noch keine Preise hinterlegt.</em>
                </td>
              </tr>
            </tbody>

            <tfoot>
              <tr>
                <td colspan="3" />
                <td class="text-right">
                  <button
                      type="button"
                      class="btn btn-xxs btn-default"
                      @click.prevent="addDailyPrice"
                  >
                    <i class="fa fa-plus" />
                    Preis hinzufügen
                  </button>
                </td>
              </tr>
            </tfoot>
          </table>
        </fieldset>
      </div>

      <div>
        <fieldset>
          <legend>Sonstige Preise</legend>

          <table class="table table-striped table-condensed">
            <thead>
              <tr>
                <th />
                <th>EUR</th>
                <th>USD</th>
              </tr>
            </thead>

            <tbody>
              <PriceRow
                  key="deposit"
                  v-model="deposit"
                  :exchange-rate="exchangeRate"
                  must-keep
              />
              <PriceRow
                  key="training"
                  v-model="training"
                  :exchange-rate="exchangeRate"
                  must-keep
              />
            </tbody>
          </table>
        </fieldset>

        <fieldset>
          <legend>Aufschläge</legend>

          <div class="row form-horizontal">
            <div class="col-sm-6">
              <HolidayDiscount
                  key="christmas"
                  v-model="christmas"
              />
            </div>
            <div class="col-sm-6">
              <HolidayDiscount
                  key="easter"
                  v-model="easter"
              />
            </div>
          </div>
        </fieldset>
      </div>
    </div>

    <div v-if="error" class="alert alert-danger">
      Speichern fehlgeschlagen: {{ error }}
    </div>

    <div class="d-flex gap-1 justify-content-start align-items-center mt-3">
      <button
          class="btn btn-primary"
          type="submit"
          :disabled="saving || missingAnyEuroPrices"
      >
        <i v-if="saving" class="fa fa-spinner fa-pulse" />
        Preise speichern
      </button>

      <button
          class="btn btn-default"
          type="reset"
          @click.prevent="loadData"
      >
        <i v-if="saving" class="fa fa-spinner fa-pulse" />
        Zurücksetzen
      </button>

      <span v-if="successTimer" class="text-success ml-3">
        <i class="fa fa-check text-success" />
        Preise erfolgreich gespeichert
      </span>
    </div>

    <div
        v-if="loading || saving"
        class="interaction-inhibitor"
    >
      <i class="fa fa-spinner fa-pulse fa-lg" />
    </div>
  </form>
</template>

<script>
import Utils from "../intervillas-drp/utils"
import PriceRow from "./BoatPrice/PriceRow.vue"
import HolidayDiscount from "./BoatPrice/HolidayDiscount.vue"
import { Price, Discount } from "./BoatPrice/models"

export default {
  components: {
    PriceRow,
    HolidayDiscount,
  },

  props: {
    endpoint: { type: String, required: true },
  },

  data() {
    return {
      loading:      true,
      saving:       false,
      error:        null,
      successTimer: null, // interval ID, set and cleared in onSubmit

      daily:     [], // array of Price({ subject: "dailyt })
      deposit:   new Price({ subject: "deposit" }),
      training:  new Price({ subject: "training" }),
      christmas: new Discount({ description: "christmas" }),
      easter:    new Discount({ description: "easter" }),

      minimumDays:  3,
      exchangeRate: null,
    }
  },

  computed: {
    missingAnyEuroPrices() {
      const { daily, deposit, training } = this,
            missing = p => !p.destroy && !p.eur
      if (daily.find(missing) || missing(deposit) || missing(training)) {
        return true
      }
      return false
    },
  },

  async mounted() {
    await this.loadData()
  },

  methods: {
    async loadData() {
      this.loading = true
      try {
        this.setData(await Utils.fetchJSON(this.endpoint))
      } finally {
        this.loading = false
      }
    },

    setData({ prices, holiday_discounts, exchange_rate_usd, minimum_days }) {
      this.error = null
      this.minimumDays = minimum_days
      this.exchangeRate = exchange_rate_usd

      const daily = {},
            deposit = new Price({ subject: "deposit" }),
            training = new Price({ subject: "training" })
      for (let i = prices.length - 1; i >= 0; --i) {
        const { id, currency, subject, value, amount } = prices[i]
        switch (subject) {
        case "daily":
          if (!daily[amount]) {
            daily[amount] = new Price({ subject: "daily", amount })
          }

          daily[amount].setValue({ id, value, currency })
          break
        case "deposit":
          deposit.setValue({ id, value, currency })
          break
        case "training":
          training.setValue({ id, value, currency })
          break
        }
      }

      let xmas, easter
      for (let i = holiday_discounts.length - 1; i >= 0; --i) {
        const discount = new Discount(holiday_discounts[i])
        switch (discount.description) {
        case "christmas":
          xmas = discount
          break
        case "easter":
          easter = discount
          break
        }
      }

      this.daily = Object.values(daily).sort((a, b) => a.amount - b.amout)
      this.deposit = deposit
      this.training = training
      this.christmas = xmas || new Discount({ description: "christmas" })
      this.easter = easter || new Discount({ description: "easter" })
    },

    payload() {
      const prices = [...this.daily, this.deposit, this.training].reduce((list, p) => {
        list.push(...p.toJSON())
        return list
      }, [])

      const holiday_discounts = [this.christmas, this.easter].reduce((list, d) => {
        if (d.persisted || d._dirty) {
          list.push(d.toJSON())
        }
        return list
      }, [])

      return { prices, holiday_discounts }
    },

    async onSubmit() {
      if (this.saving) {
        return
      }

      this.saving = true
      const boat_price = this.payload()

      try {
        this.setData(await Utils.patchJSON(this.endpoint, { boat_price }))
        this.successTimer = setTimeout(() => {
          this.successTimer = null
        }, 2500)
      } catch (err) {
        if (err.response && err.response.data) {
          this.error = err.response.data
        } else {
          this.error = err.message
        }
      } finally {
        this.saving = false
      }
    },

    addDailyPrice() {
      const last = this.daily[this.daily.length - 1]
      if (last) {
        // XXX: be smarter about holes in price list?
        this.daily.push(new Price({ subject: "daily", amount: last.amount + 1 }))
      } else {
        this.daily.push(new Price({ subject: "daily", amount: this.minimumDays }))
      }
    },

    keepDailyPrice(idx) {
      this.daily[idx].destroy = false
    },

    destroyDailyPrice(idx) {
      this.daily[idx].destroy = true
    },
  },
}
</script>

<style lang="scss" scoped>
  @media screen and (min-width: 1440px) {
    .fields {
      display: flex;
      > div {
        flex-grow: 1;
        max-width: 50%;
      }
    }
  }

  .inhibit-interaction {
    position: relative;

    .interaction-inhibitor {
      position: absolute;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
      z-index: 1001;

      background-color: #fff8;
      color: #666;
      font-size: 200%;

      display: flex;
      justify-content: center;
      align-items: center;
      gap: 1rem;
    }
  }
</style>
