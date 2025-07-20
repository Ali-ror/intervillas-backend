<template>
  <AsyncLoader url="/admin/my_booking_pal/manager.json" @data="onData">
    <form
        v-if="remoteData"
        class="pb-5"
        @submit.prevent="save"
    >
      <UiCard
          heading="Details"
          body-class="form-horizontal"
          collapsible
          open
      >
        <div class="form-group">
          <label for="pm_website" class="control-label col-sm-3">
            Login
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <dl class="form-control-static mbp-pm-login">
              <dt>Email</dt>
              <dd>{{ details.email }}</dd>
              <dt>Password</dt>
              <dd> <i class="fa fa-ellipsis-h fa-lg text-muted" /> </dd>
              <dt>Account</dt>
              <dd>{{ details.accountId }}</dd>
              <dt>ID</dt>
              <dd>{{ id }}</dd>
            </dl>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_language" class="control-label col-sm-3">
            Language
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <select
                id="pm_language"
                v-model="details.language"
                class="form-control"
                required
            >
              <option value="de">
                German
              </option>
              <option value="en">
                English
              </option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_language" class="control-label col-sm-3">
            Currency
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <div class="form-control-static">
              {{ details.currency }}
              <small class="text-muted">
                (For simplicity, this cannot be changed.)
              </small>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_name" class="control-label col-sm-3">
            Name
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_name"
                v-model="details.fullName"
                type="text"
                class="form-control"
                required
            >
          </div>
        </div>

        <div class="form-group">
          <label for="pm_company_name" class="control-label col-sm-3">
            Company Name
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_company_name"
                v-model="details.companyName"
                type="text"
                class="form-control"
                required
            >
          </div>
        </div>

        <div class="form-group">
          <label for="pm_company_streetAddress" class="control-label col-sm-3">
            Street Address
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_company_streetAddress"
                v-model="details.companyAddress.streetAddress"
                type="text"
                class="form-control"
                required
            >
          </div>
        </div>

        <div class="form-group">
          <label for="pm_company_zip" class="control-label col-sm-3">
            ZIP code
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_company_zip"
                v-model="details.companyAddress.zip"
                type="text"
                class="form-control"
                required
            >
          </div>
        </div>

        <div class="form-group">
          <label for="pm_company_city" class="control-label col-sm-3">
            City
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_company_city"
                v-model="details.companyAddress.city"
                type="text"
                class="form-control"
                required
            >
          </div>
        </div>

        <div class="form-group">
          <label for="pm_company_state" class="control-label col-sm-3">
            State/Region
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_company_state"
                v-model="details.companyAddress.state"
                type="text"
                class="form-control"
                :required="details.companyAddress.country.toLowerCase() === 'us'"
            >
            <span class="help-block">only for US</span>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_company_country" class="control-label col-sm-3">
            Country Code
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_company_country"
                v-model="details.companyAddress.country"
                maxlength="2"
                type="text"
                class="form-control"
                required
            >
            <span class="help-block">2-digit ISO code</span>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_website" class="control-label col-sm-3">
            Website
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_website"
                v-model="details.website"
                type="text"
                class="form-control"
                required
            >
          </div>
        </div>

        <div class="form-group">
          <label for="pm_phone_number" class="control-label col-sm-3">
            Phone
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <div class="d-flex gap-1">
              <select
                  id="pm_phone_cc"
                  v-model="details.phone.countryCode"
                  class="form-control"
              >
                <option value="+1">
                  +1 (US/CA)
                </option>
                <option value="+41">
                  +49 (CH)
                </option>
                <option value="+49">
                  +49 (DE)
                </option>
              </select>
              <input
                  id="pm_phone_number"
                  v-model="details.phone.number"
                  type="text"
                  class="form-control"
                  required
              >
            </div>
          </div>
        </div>
      </UiCard>

      <UiCard
          heading="Genaral Policies"
          body-class="form-horizontal"
          collapsible
          open
      >
        <div class="form-group">
          <label for="pm_policy_terms" class="control-label col-sm-3">
            URL to Terms
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="pm_policy_terms"
                v-model="policies.terms"
                type="text"
                required
                class="form-control"
            >
          </div>
        </div>

        <div class="form-group">
          <label for="pm_policy_checkin" class="control-label col-sm-3">
            Check-In
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <select
                id="pm_policy_checkin"
                v-model="policies.checkInTime"
                required
                class="form-control"
            >
              <option
                  v-for="o in checkIOtimes"
                  :key="o.value"
                  :value="o.value"
                  v-text="o.text"
              />
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_policy_checkout" class="control-label col-sm-3">
            Check-Out
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <select
                id="pm_policy_checkout"
                v-model="policies.checkOutTime"
                required
                class="form-control"
            >
              <option
                  v-for="o in checkIOtimes"
                  :key="o.value"
                  :value="o.value"
                  v-text="o.text"
              />
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_policy_leadtime" class="control-label col-sm-3">
            Lead Time
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <div class="input-group">
              <input
                  id="pm_policy_leadtime"
                  v-model.number="policies.leadTime"
                  type="number"
                  min="0"
                  max="7"
                  class="form-control"
                  required
              >
              <div class="input-group-addon">
                {{ policies.leadTime === 1 ? "day" : "days" }}
              </div>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label for="pm_policy_leadtime" class="control-label col-sm-3">
            Fees/Taxes
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <p class="form-control-static">
              <em class="text-muted">Cleaning fees, and sales/tourist taxes are always included.</em>
            </p>
          </div>
        </div>
      </UiCard>

      <UiCard
          heading="Payment Policy"
          body-class="form-horizontal"
          collapsible
          open
      >
        <div class="form-group">
          <label for="pm_payment_policy_type" class="control-label col-sm-3">
            Payment Type
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <select
                id="pm_payment_policy_type"
                v-model="policies.paymentPolicy.type"
                class="form-control"
                required
            >
              <option value="SPLIT">
                Split into downpayment and remainder
              </option>
              <option value="FULL">
                Full payment on booking
              </option>
            </select>
          </div>
        </div>

        <template v-if="policies.paymentPolicy.type === 'SPLIT'">
          <div class="form-group">
            <label for="pm_split_payment_days" class="control-label col-sm-3">
              Payment deadline
            </label>
            <div class="col-sm-9 col-md-8 col-lg-7">
              <input
                  id="pm_split_payment_days"
                  v-model.number="policies.paymentPolicy.splitPayment.secondPaymentDays"
                  type="number"
                  min="1"
                  class="form-control"
                  required
              >
              <span class="help-block">
                as number of
                {{ policies.paymentPolicy.splitPayment.secondPaymentDays === 1 ? 'day' : 'days' }}
                before Check-In
              </span>
            </div>
          </div>

          <div class="form-group">
            <label for="pm_split_payment_amount" class="control-label col-sm-3">
              Amount
            </label>
            <div class="col-sm-9 col-md-8 col-lg-7">
              <input
                  id="pm_split_payment_amount"
                  v-model.number="policies.paymentPolicy.splitPayment.value"
                  type="text"
                  class="form-control"
                  required
              >
            </div>
          </div>

          <div class="form-group">
            <label for="pm_split_payment_type" class="control-label col-sm-3">
              Type
            </label>
            <div class="col-sm-9 col-md-8 col-lg-7">
              <select
                  id="pm_split_payment_type"
                  v-model="policies.paymentPolicy.splitPayment.depositType"
                  class="form-control"
                  required
              >
                <option value="PERCENTAGE">
                  percent of total booking value
                </option>
                <option value="FLAT">
                  flat value in {{ details.currency }}
                </option>
              </select>
            </div>
          </div>
        </template>
      </UiCard>

      <UiCard
          heading="Cancellation Policy"
          body-class="form-horizontal"
          collapsible
          open
      >
        <div class="form-group">
          <label for="pm_cancellation_policy_type" class="control-label col-sm-3">
            Refunds
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <select
                id="pm_cancellation_policy_type"
                v-model="policies.cancellationPolicy.type"
                class="form-control"
                required
            >
              <option value="FULLY_REFUNDABLE">
                Full refund
              </option>
              <option value="NON_REFUNDABLE">
                No refund
              </option>
              <option value="MANUAL">
                Manual refund
              </option>
            </select>
          </div>
        </div>

        <template v-if="policies.cancellationPolicy.type === 'MANUAL'">
          <div class="form-group">
            <label for="pm_cancellation_policy_refund_type" class="control-label col-sm-3">
              Refund type
            </label>
            <div class="col-sm-9 col-md-8 col-lg-7">
              <select
                  id="pm_cancellation_policy_refund_type"
                  v-model="policies.cancellationPolicy.manualPolicy.type"
                  class="form-control"
                  required
              >
                <option value="FLAT">
                  Flat value
                </option>
                <option value="PERCENTAGE">
                  Percentage value
                </option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label class="control-label col-sm-3">
              Refund steps
            </label>
            <div class="col-sm-9 col-md-8 col-lg-7">
              <div
                  v-for="step, i in policies.cancellationPolicy.manualPolicy.manualPolicies"
                  :key="i"
                  class="form-control-static"
              >
                <div class="d-flex gap-1">
                  <div class="input-group">
                    <input
                        v-model.number="step.beforeDays"
                        type="number"
                        min="0"
                        class="form-control"
                        required
                    >
                    <div class="input-group-addon">
                      {{ step.beforeDays === 1 ? "day" : "days" }} before check-in
                    </div>
                  </div>

                  <div class="input-group">
                    <input
                        v-model.number="step.chargeValue"
                        type="number"
                        min="0"
                        class="form-control"
                        required
                    >
                    <div class="input-group-addon">
                      {{ policies.cancellationPolicy.manualPolicy.type === "FLAT" ? details.currency : "% of total" }}
                    </div>
                  </div>

                  <div class="input-group">
                    <input
                        v-model.number="step.cancellationFee"
                        type="number"
                        min="0"
                        class="form-control"
                        required
                    >
                    <div class="input-group-addon">
                      {{ details.currency }} extra fee
                    </div>
                  </div>

                  <button
                      class="btn btn-warning"
                      type="button"
                      title="remove step"
                      @click="policies.cancellationPolicy.manualPolicy.manualPolicies.splice(i, 1)"
                  >
                    <i class="fa fa-trash" />
                  </button>
                </div>
              </div>
              <div class="text-right">
                <button
                    class="btn btn-default"
                    type="button"
                    title="add step"
                    @click="policies.cancellationPolicy.manualPolicy.manualPolicies.push({
                      beforeDays: 0,
                      chargeValue: 0,
                      cancellationFee: 0,
                    })"
                >
                  <i class="fa fa-plus" />
                </button>
              </div>
            </div>
          </div>
        </template>
      </UiCard>

      <div class="form-group">
        <div class="col-sm-offset-3 col-sm-9 col-md-8 col-lg-7">
          <div class="d-flex gap-1">
            <button
                class="btn btn-primary"
                type="submit"
                :disabled="saving"
            >
              Save
            </button>

            <button
                class="btn btn-default"
                type="reset"
                :disabled="saving"
                @click.prevent="reset"
            >
              Reset
            </button>
          </div>
        </div>
      </div>
    </form>
  </AsyncLoader>
</template>

<script>
import UiCard from "../../components/UiCard.vue"
import Utils from "../../intervillas-drp/utils"
import AsyncLoader from "../AsyncLoader.vue"

const pad = v => v < 10 ? `0${v}` : v

/**
 * Options for time select, 0:00 am to 11:30 pm, in 30min steps.
 *
 * @type {{value: string, text: string}[]}
 */
const CHECK_IO_TIMES = [...new Array(24)].flatMap((_, i) => {
  const h24 = pad(i),
        h12 = i > 12 ? i - 12 : i,
        am = i >= 12 ? "pm" : "am"
  return [
    { value: `${h24}:00:00`, text: `${h12}:00 ${i === 12 ? "noon" : am}` },
    { value: `${h24}:30:00`, text: `${h12}:30 ${am}` },
  ]
})

export default {
  name: "MyBookingPalManager",

  components: { UiCard, AsyncLoader },

  data() {
    return {
      saving: false,

      remoteData: null,
      details:    null, // can be edited
      policies:   null, // can be edited
      payment:    null, // can be edited
      extra:      null, // can be edited

      checkIOtimes: CHECK_IO_TIMES,
    }
  },

  computed: {
    id() {
      return this.remoteData?.id
    },
  },

  methods: {
    onData(data) {
      this.remoteData = data
      this.setData(data)
    },

    setData({ companyDetails, policies, payment }) {
      this.details = companyDetails || {}
      this.policies = policies || []
      this.payment = payment || {}
    },

    async save() {
      this.saving = true

      const payload = Object.assign({}, this.remoteData, {
        companyDetails: this.details,
        policies:       this.policies,
        payment:        this.payment,
      })

      const data = await Utils.patchJSON("/admin/my_booking_pal/manager.json", payload)
      this.onData(data)
      this.saving = false
    },

    reset() {
      this.setData(Utils.dup(this.remoteData))
    },
  },
}
</script>

<style lang="scss" scoped>
  .mbp-pm-login {
    display: grid;
    grid-template-columns: max-content min-content;
    gap: 1rem;

    dt {
      font-weight: normal;

      &::after {
        content: ":"
      }
    }
  }
</style>
