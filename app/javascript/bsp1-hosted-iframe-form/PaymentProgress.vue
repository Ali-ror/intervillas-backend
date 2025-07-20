<template>
  <div class="alert alert-success">
    <i class="fa fa-check" />

    {{ "bsp1_form.success" | translate }}
  </div>
</template>

<script>
import { translate } from "@digineo/vue-translate"
import axios from "axios"

export default {
  name:  "PaymentProgress",
  props: {
    provider:     { type: String, required: true },
    processId:    { type: [String, Number], required: true },
    inquiryToken: { type: String, required: true },
    redirect:     { type: String, required: false, default: null },
  },

  mounted() {
    this.poll()
  },

  methods: {
    translate,
    poll() {
      axios.get("/api/progress", {
        params: {
          inquiry_token: this.inquiryToken,
          provider:      this.provider,
          process_id:    this.processId,
        },
      }).then(response => {
        // console.log(response)
        const isPaidAndBooked = (
          response.data.status === "PAID" || response.data.status === "completed"
        ) && response.data.booking_status === "Booking"

        if (isPaidAndBooked) {
          if (this.redirect) {
            location.assign(this.redirect)
          } else {
            location.reload()
          }
        } else {
          setTimeout(() => {
            this.poll()
          }, 1000)
        }
      }).catch(error => {
        this.showAlert = "error"
        this.errorMessage = error.message
      })
    },
  },
}
</script>

<style scoped>
.nav-tabs > li > a {
  cursor: pointer;
}
</style>
