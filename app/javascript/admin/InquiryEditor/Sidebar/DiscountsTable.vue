<template>
  <table class="table table-condensed small">
    <tbody>
      <tr
          v-for="discount in discounts"
          :key="discount.ident"
          :class="{ 'hidden-print': !discount.value }"
      >
        <td
            class="text-right"
            v-text="discount.percentage"
        />
        <td>
          {{ discount.subject | translate({ scope: "shared.discount.subjects" }) }}
        </td>
        <td class="text-muted small">
          <em v-if="discount.value">
            {{ discount | formatDateRange }}
          </em>
        </td>
        <td v-if="!readOnly" class="text-right hidden-print">
          <button
              class="btn btn-xxs"
              :class="discount.value ? 'btn-primary' : 'btn-default'"
              type="button"
              :title="title(discount)"
              @click.prevent="$emit('edit', discount)"
          >
            <i
                class="fa fa-fw small"
                :class="discount.value ? 'fa-pencil' : 'fa-plus'"
            />
          </button>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
import { formatDateRange } from "../../../lib/DateFormatter"
import { translate } from "@digineo/vue-translate"

export default {
  filters: {
    formatDateRange,
  },

  props: {
    discounts: { type: Object, required: true },
    readOnly:  { type: Boolean, default: false },
  },

  methods: {
    title(discount) {
      const action = discount.value ? "edit" : "add",
            kind = discount.subject === "special" ? "discount" : "addition"

      return [
        translate(discount.subject, { scope: "shared.discount.subjects" }),
        translate(`shared.discount.kinds.${kind}.${action}`),
      ].join(": ")
    },
  },
}
</script>
