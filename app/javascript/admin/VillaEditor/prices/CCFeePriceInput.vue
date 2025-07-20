<template>
  <div v-if="currency === 'USD'" class="row">
    <div class="col-sm-6">
      <div class="input-group">
        <label
            class="sr-only"
            :for="`cc_fee_price_input_${id}_excl`"
            v-text="labelExclCCFee"
        />
        <input
            v-if="readonly"
            :id="`cc_fee_price_input_${id}_excl`"
            :value="exclCCFee"
            :placeholder="labelExclCCFee"
            type="number"
            class="form-control"
            readonly
        >
        <input
            v-else
            :id="`cc_fee_price_input_${id}_excl`"
            v-model.number="exclCCFee"
            :placeholder="labelExclCCFee"
            type="number"
            class="form-control"
            min="0"
            step="0.01"
        >
        <span class="input-group-addon">
          <CurrencyIcon :currency="currency"/>
        </span>
      </div>
    </div>

    <div class="col-sm-6">
      <div class="input-group">
        <label
            class="sr-only"
            :for="`cc_fee_price_input_${id}_incl`"
            v-text="labelInclCCFee"
        />
        <input
            v-if="readonly"
            :id="`cc_fee_price_input_${id}_incl`"
            :value="inclCCFee"
            :placeholder="labelInclCCFee"
            type="number"
            class="form-control"
            readonly
        >
        <input
            v-else
            :id="`cc_fee_price_input_${id}_incl`"
            v-model.number="inclCCFee"
            :placeholder="labelInclCCFee"
            type="number"
            class="form-control"
            min="0"
            step="0.01"
        >
        <span class="input-group-addon">
          <CurrencyIcon :currency="currency"/>
        </span>
      </div>
    </div>
  </div>

  <div v-else class="input-group">
    <label
        class="sr-only"
        :for="`cc_fee_price_input_${id}`"
        v-text="label"
    />
    <input
        v-if="readonly"
        :id="`cc_fee_price_input_${id}`"
        :value="inclCCFee"
        :placeholder="label"
        type="number"
        class="form-control"
        readonly
    >
    <input
        v-else
        :id="`cc_fee_price_input_${id}`"
        v-model.number="inclCCFee"
        :placeholder="label"
        type="number"
        class="form-control"
        min="0"
        step="0.01"
    >
    <span class="input-group-addon">
      <CurrencyIcon :currency="currency"/>
    </span>
  </div>
</template>

<script>
import CurrencyIcon from "../CurrencyIcon.vue"

const DISPLAY_PRICE_PRECISION = Math.floor(Math.pow(10, 2)) // two decimal places

function displayPrice(val, divisor = 1) {
  if (val) {
    val /= divisor
    val = Math.round(val * DISPLAY_PRICE_PRECISION) / DISPLAY_PRICE_PRECISION
  }
  return val
}

export default {
  components: {
    CurrencyIcon,
  },

  props: {
    id:        { type: String, default: null },
    title:     { type: String, required: true }, // label and placeholder
    ccPercent: { type: Number, required: true },
    currency:  { type: String, required: true }, // EUR | USD
    value:     { type: [Number, String], default: null }, // v-model, gross price
    readonly:  { type: Boolean, default: false },
  },

  computed: {
    label() {
      const { title, currency } = this
      return `${title} (${currency})`
    },

    labelInclCCFee() {
      const { title, currency } = this
      return `${title} (${currency}, inkl. KK-Gebühr)`
    },

    labelExclCCFee() {
      const { title, currency } = this
      return `${title} (${currency}, ohne KK-Gebühr)`
    },

    ccFactor() {
      return 1 + (this.ccPercent / 100)
    },

    inclCCFee: {
      get() {
        return displayPrice(this.value)
      },
      set(val) {
        this.$emit("input", val)
      },
    },

    exclCCFee: {
      get() {
        const { value, ccFactor } = this
        return displayPrice(value, ccFactor)
      },
      set(val) {
        if (val == null || val === "") {
          this.inclCCFee = null
        } else {
          this.inclCCFee = val * this.ccFactor
        }
      },
    },
  },
}
</script>
