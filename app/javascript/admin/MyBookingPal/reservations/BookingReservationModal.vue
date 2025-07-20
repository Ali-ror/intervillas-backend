<template>
  <VModal
      name="booking-reservation"
      :max-width="600"
      height="auto"
      adaptive
      @before-close="onCloseModal"
  >
    <UiCard
        heading="Reservation Details"
        body-class="reservation-detail"
        footer-class="text-right"
        class="mb-0"
    >
      <AsyncLoader :url="url" @data="onData">
        <table v-if="reservation" class="table table-condensed table-bordered">
          <tbody>
            <tr>
              <th>Date</th>
              <td>{{ reservation.date }}</td>
            </tr>
            <tr>
              <th>Type</th>
              <td>
                <ReservationBadge :type="reservation.type"/>
              </td>
            </tr>
            <tr>
              <th>Channel</th>
              <td>{{ reservation.channel }}</td>
            </tr>
            <tr>
              <th>Reservation ID</th>
              <td>
                {{ reservation.reservation_id }}
                <small class="text-muted">(MyBookingPal)</small>
              </td>
            </tr>
            <tr>
              <th>Product / Villa</th>
              <td>
                <template v-if="reservation.product.id">
                  <a :href="reservation.product.url" v-text="reservation.product.id"/>
                  <small class="ml-2 text-muted">(MyBookingPal)</small> /
                </template> {{ reservation.product.name }}
              </td>
            </tr>
            <tr>
              <th>Inquiry ID</th>
              <td>
                <a :href="reservation.inquiry.url">
                  <Component
                      :is="reservation.isCancelled ? 's' : 'span'"
                  >{{ reservation.inquiry.number }}</Component>
                </a>
                <small class="ml-2 text-muted">(Intervilla)</small>
              </td>
            </tr>
            <tr>
              <th>Booking dates</th>
              <td>{{ reservation.dates }}</td>
            </tr>
            <tr>
              <th>Total Price</th>
              <td>
                {{ currency(reservation.total, 'USD') }}
                <small class="ml-2 text-muted">(paid by tenant)</small>
              </td>
            </tr>
            <tr v-if="reservation.cleaning != null">
              <th>Deposit</th>
              <td>
                {{ currency(reservation.cleaning, 'USD') }}
              </td>
            </tr>
            <tr v-if="reservation.deposit != null">
              <th>Deposit</th>
              <td>
                {{ currency(reservation.deposit, 'USD') }}
              </td>
            </tr>
            <tr v-if="reservation.commission != null">
              <th>Commission</th>
              <td>
                {{ currency(reservation.commission, 'USD') }}
              </td>
            </tr>
            <tr>
              <th>{{ reservation.type === 'cancel' ? 'Refund' : 'Rent' }}</th>
              <td>
                {{ currency(reservation.rent, 'USD') }}
                <small class="ml-2 text-muted">(computed)</small>
              </td>
            </tr>
          </tbody>
        </table>

        <details v-if="reservation">
          <summary>Show raw data</summary>
          <JsonTree :value="reservation.payload" :level="3"/>
        </details>
      </AsyncLoader>

      <template #footer>
        <button class="btn btn-sm btn-primary" @click.prevent="hideModal">
          Close
        </button>
      </template>
    </UiCard>
  </VModal>
</template>

<script>
import UiCard from "../../../components/UiCard.vue"
import AsyncLoader from "../../AsyncLoader.vue"
import JsonTree from "./JsonTree.vue"
import { Reservation } from "./reservation"
import ReservationBadge from "./ReservationBadge.vue"
import { currency } from "../../CurrencyFormatter"

export default {
  components: {
    UiCard,
    AsyncLoader,
    JsonTree,
    ReservationBadge,
  },

  data() {
    return {
      url:         null,
      reservation: null,
    }
  },

  methods: {
    currency,

    onData(reservation) {
      this.reservation = new Reservation(reservation)
    },

    showModal(url) {
      this.url = url
      document.querySelector("body").style.overflow = "hidden"
      this.$modal.show("booking-reservation")
    },

    hideModal() {
      this.$modal.hide("booking-reservation")
    },

    onCloseModal() {
      document.querySelector("body").style.overflow = ""
      this.url = null
      this.reservation = null
    },
  },
}
</script>

<style>
  .reservation-detail {
    max-height: 80vh;
    overflow-y: scroll;
  }
  .reservation-detail summary {
    cursor: pointer;
    display: list-item;
  }
</style>
