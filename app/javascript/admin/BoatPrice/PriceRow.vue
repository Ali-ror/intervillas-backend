<template>
  <tr>
    <td
        v-if="price.destroy"
        class="text-danger"
        title="wird gelöscht"
    >
      <i class="fa fa-trash text-danger" />
      <s v-text="price.label" />
    </td>
    <td
        v-else-if="price._dirty"
        class="text-warning"
        title="ungespeichert"
    >
      <i class="fa fa-save text-warning" />
      {{ price.label }}
    </td>
    <td v-else v-text="price.label" />

    <td :class="{ 'has-error': !price.destroy && !price.eur }">
      <PriceInput
          v-model="price"
          currency="EUR"
          required
          :exchange-rate="exchangeRate"
      />
      <div v-if="!price.destroy && !price.eur" class="help-block">
        muss ausgefüllt werden
      </div>
    </td>
    <td>
      <PriceInput
          v-model="price"
          currency="USD"
          :exchange-rate="exchangeRate"
      />
    </td>

    <td v-if="!mustKeep" class="text-right">
      <button
          v-if="price.destroy"
          type="button"
          class="btn btn-xxs btn-warning"
          @click="$emit('keep')"
      >
        <i class="fa fa-refresh" /> behalten
      </button>
      <button
          v-else
          type="button"
          class="btn btn-xxs btn-danger"
          :title="`Preise für ${price.label} entfernen`"
          @click="$emit('destroy')"
      >
        <i class="fa fa-trash" /> löschen
      </button>
    </td>
  </tr>
</template>

<script>
import PriceInput from "./PriceInput.vue"
import { Price } from "./models"

export default {
  components: {
    PriceInput,
  },

  props: {
    value:        { type: Price, required: true }, // v-model
    exchangeRate: { type: Number, default: null },
    mustKeep:     { type: Boolean, default: false },
  },

  computed: {
    price: {
      get() {
        return this.value
      },
      set(val) {
        this.$emit("input", val)
      },
    },
  },
}
</script>
