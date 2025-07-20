<template>
  <div :class="inputGroupClass">
    <span class="input-group-btn" :title="shouldDisableDecrementBtn ? minDisabledTitle : null">
      <button
          class="btn btn-default"
          :disabled="shouldDisableDecrementBtn"
          @click.prevent="increment(-1)"
      >
        <i class="fa fa-fw fa-minus" />
      </button>
    </span>
    <input
        :id="id"
        v-model.number="num"
        :name="name"
        class="form-control"
        type="number"
        :min="min"
        :max="max"
        :step="stp"
    >
    <span class="input-group-btn" :title="shouldDisableIncrementBtn ? maxDisabledTitle : null">
      <button
          class="btn btn-default"
          :disabled="shouldDisableIncrementBtn"
          @click.prevent="increment(1)"
      >
        <i class="fa fa-fw fa-plus" />
      </button>
    </span>
  </div>
</template>

<script>
export default {
  props: {
    id:    { type: String, default: null },
    name:  { type: String, default: null },
    min:   { type: [String, Number], default: null },
    max:   { type: [String, Number], default: null },
    step:  { type: [String, Number], default: 1 },
    value: { type: [String, Number], default: null },

    /** @optional input group size */
    size:             { type: String, default: "md", validator: v => ["sm", "md", "lg"].includes(v) },
    minDisabledTitle: { type: String, default: null },
    maxDisabledTitle: { type: String, default: null },
  },

  computed: {
    num: {
      get() {
        return Number(this.value || 0)
      },

      set(val) {
        this.$emit("input", val)
      },
    },

    stp() {
      return Number(this.step || 1)
    },

    inputGroupClass() {
      const cls = ["input-group"],
            { size } = this
      if (size === "sm" || size === "lg") {
        cls.push(`input-group-${size}`)
      }
      return cls
    },

    shouldDisableDecrementBtn() {
      const { min, num, stp } = this
      return min !== null && num - stp < min
    },

    shouldDisableIncrementBtn() {
      const { max, num, stp } = this
      return max !== null && num + stp > max
    },
  },

  methods: {
    increment(factor) {
      const { num, min, max, stp } = this

      if (factor > 0 && num < min) {
        this.num = min
      } else if (factor < 0 && num > max) {
        this.num = max
      } else {
        this.num += Math.sign(factor) * stp
      }
    },
  },
}
</script>
