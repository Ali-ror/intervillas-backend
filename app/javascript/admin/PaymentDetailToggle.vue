<template>
  <form class="form-inline" @submit.prevent>
    <div class="form-group checkbox">
      <label>
        <input
            id="toggle-payment-details"
            v-model="show"
            type="checkbox"
            name="toggle-payment-details"
        >
        <slot />
      </label>
    </div>
  </form>
</template>

<script>
export default {
  data() {
    return {
      show: false,
    }
  },

  watch: {
    show(val) {
      console.log(val)
      this.toggleDetails(val)
    },
  },

  methods: {
    toggleDetails() {
      for (const tbody of document.querySelectorAll("tbody.payments")) {
        tbody.classList.toggle("d-none", !this.show)
      }
    },
  },
}
</script>
