<template>
  <div class="panel panel-default">
    <div class="text-center py-3">
      <span class="d-block lead text-primary mb-0">
        <strong>{{ labels.price_from }} {{ villa.price_from }}</strong>
      </span>
      <small class="text-muted">
        {{ priceTimeUnit }}
      </small>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    villa:  { type: Object, required: true },
    labels: { type: Object, required: true },
  },

  computed: {
    priceTimeUnit() {
      const { villa, labels } = this,
            { weekly_pricing, beds_count, minimum_people } = villa,
            mode = weekly_pricing ? "weekly" : "nightly",
            unit = labels.price_time_unit[mode]

      return unit.replace(/%{count}/, weekly_pricing ? beds_count : minimum_people)
    },
  },
}
</script>
