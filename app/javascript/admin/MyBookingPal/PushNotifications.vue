<template>
  <AsyncLoader url="/admin/my_booking_pal/push_notification.json" @data="onData">
    <form class="pb-5 form-horizontal" @submit.prevent="save">
      <div class="form-group">
        <div class="form-group">
          <label for="push_notification_async_push" class="control-label col-sm-3">
            Async. push message URL
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <p class="form-control-static">
              <code>{{ urls.async_push || '(not set)' }}</code>
            </p>
            <span class="help-block">
              Endpoint for product/villa validation results and image import updates.
            </span>
          </div>
        </div>

        <div class="form-group">
          <label for="push_notification_reservation_link" class="control-label col-sm-3">
            Reservation message URL
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <p class="form-control-static">
              <code>{{ urls.reservation || '(not set)' }}</code>
            </p>
            <span class="help-block">
              Endpoint for bookings (create, update, cancel messages).
            </span>
          </div>
        </div>

        <div class="form-group">
          <label class="control-label col-sm-3">
            Format
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <div class="form-control-static">
              JSON
            </div>
          </div>
        </div>

        <div class="form-group">
          <label for="push_notification_reservation_link" class="control-label col-sm-3">
            Update base URL
          </label>
          <div class="col-sm-9 col-md-8 col-lg-7">
            <input
                id="push_notification_reservation_link"
                v-model="urls.base"
                type="text"
                required
                class="form-control"
            >
          </div>
        </div>

        <div class="form-group">
          <div class="col-sm-offset-3 col-sm-9 col-md-8 col-lg-7">
            <button
                class="btn btn-primary"
                type="submit"
                :disabled="saving"
            >
              Save
            </button>
          </div>
        </div>
      </div>
    </form>
  </AsyncLoader>
</template>

<script>
import Utils from "../../intervillas-drp/utils"
import AsyncLoader from "../AsyncLoader.vue"

export default {
  components: {
    AsyncLoader,
  },

  data() {
    return {
      saving: false,

      urls: {
        base:        null,
        async_push:  null,
        reservation: null,
      },
    }
  },

  methods: {
    onData({ urls }) {
      this.reset(urls)
    },

    async save() {
      this.saving = true

      const { urls } = await Utils.patchJSON("/admin/my_booking_pal/push_notification.json", {
        base_url: this.urls.base,
      })
      this.reset(urls)
      this.saving = false
    },

    reset({ base, async_push, reservation }) {
      this.urls = { base, async_push, reservation }
    },
  },
}
</script>
