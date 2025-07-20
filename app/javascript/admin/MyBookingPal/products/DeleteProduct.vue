<template>
  <UiCard
      heading="Danger Zone"
      class="border-danger"
      collapsible
  >
    <form @submit.prevent="confirmDelete">
      <div class="checkbox">
        <label>
          <input
              type="checkbox"
              name="confirm_delete"
              required
          > I understand that this will remove the Villa from MyBookingPal.
          <span class="help-block small">
            Re-creating the product later is possible, but requires to re-validate
            the product.
          </span>
        </label>
      </div>

      <div class="checkbox">
        <label>
          <input
              type="checkbox"
              name="confirm_reservations"
              required
          > I understand that existing reservations must still be honored.
          <span class="help-block small">
            Existing reservations loose the cross-reference to this product,
            so navigating from the blocking to the product won't be possible.
          </span>
        </label>
      </div>

      <div class="checkbox">
        <label>
          <input
              type="checkbox"
              name="confirm_disable"
              required
          > I have considered deactivating the product instead.
          <span class="help-block small">
            Deactivating will suspend new reservations temporarily.
          </span>
        </label>
      </div>

      <button
          class="btn btn-danger"
          :disabled="deleting"
          type="submit"
      >
        Delete Product
      </button>
    </form>
  </UiCard>
</template>

<script>
import UiCard from "../../../components/UiCard.vue"
import Utils from "../../../intervillas-drp/utils"

export default {
  components: {
    UiCard,
  },

  props: {
    url: { type: String, required: true },
  },

  data() {
    return {
      deleting: false,
    }
  },

  methods: {
    async confirmDelete() {
      if (!confirm("This product will be deleted. Continue?")) {
        return
      }

      this.deleting = true
      const { location } = await Utils.deleteJSON(this.url)
      window.location.assign(location)
    },
  },
}
</script>
