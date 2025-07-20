<template>
  <UiCard header-class="d-flex justify-content-between align-items-baseline" no-body>
    <template #heading>
      {{ title }}

      <span v-if="$refs.loader && !compact" class="ml-auto d-flex gap-1">
        <button
            class="btn btn-xxs btn-default"
            @click="expandPrices = !expandPrices"
        >
          <i class="fa fa-fw" :class="expandPrices ? 'fa-eye-slash' : 'fa-eye'"/>
          {{ expandPrices ? "Show only Total" : "Breakdown Prices" }}
        </button>

        <button
            class="btn btn-xxs btn-default"
            :disabled="$refs.loader.loading"
            @click="$refs.loader.fetchData()"
        >
          <i
              class="fa fa-fw"
              :class="$refs.loader.loading ? ['fa-spinner','fa-pulse'] : 'fa-refresh'"
          />
          Refresh List
        </button>
      </span>
    </template>

    <AsyncLoader
        ref="loader"
        :url="paginationUrl"
        @data="onData"
    >
      <div v-if="entries.length === 0" class="alert alert-warning m-3">
        No reservations found, yet.
      </div>
      <table v-else class="table table-striped table-condensed m-0">
        <thead>
          <tr>
            <th>Received</th>
            <th>Type</th>

            <template v-if="!compact">
              <th>Channel</th>
              <th>Booking dates</th>

              <th v-if="expandPrices" class="text-center">Prices</th>
              <th v-else class="text-right">Total</th>

              <th class="text-right">
                Reservation ID
                <div class="small">(MyBookingPal)</div>
              </th>
              <th class="text-right">
                Inquiry ID
                <div class="small">(Intervilla)</div>
              </th>
              <th v-if="!hideProduct" class="text-right">
                Product/Villa
              </th>
            </template>

            <th />
          </tr>
        </thead>

        <tbody>
          <tr v-for="r in entries" :key="r.id">
            <td>{{ r.date }}</td>
            <td>
              <ReservationBadge :type="r.type"/>
            </td>

            <template v-if="!compact">
              <td>{{ r.channel }}</td>
              <td v-if="!compact">{{ r.dates }}</td>

              <td class="text-right">
                <table v-if="expandPrices" class="mx-auto">
                  <colgroup>
                    <col style="width: 1em">
                    <col style="width: 100px">
                    <col style="width: 100px;">
                  </colgroup>
                  <tr>
                    <td class="text-left"/>
                    <td class="text-right" v-text="currency(r.rent, 'USD')" />
                    <td class="text-left text-muted small pl-3">{{ r.type === 'cancel' ? 'refund' : 'rent' }}</td>
                  </tr>
                  <tr v-if="r.cleaning != null && r.cleaning > 0">
                    <td class="text-left">+</td>
                    <td class="text-right" v-text="currency(r.cleaning, 'USD')" />
                    <td class="text-left text-muted small pl-3">cleaning</td>
                  </tr>
                  <tr v-if="r.deposit != null && r.deposit > 0">
                    <td class="text-left">+</td>
                    <td class="text-right" v-text="currency(r.deposit, 'USD')" />
                    <td class="text-left text-muted small pl-3">deposit</td>
                  </tr>
                  <tr v-if="r.commission != null && r.commission > 0">
                    <td class="text-left">+</td>
                    <td class="text-right" v-text="currency(r.commission, 'USD')" />
                    <td class="text-left text-muted small pl-3">commission</td>
                  </tr>
                  <tr style="font-weight: bold">
                    <td class="border-top text-left" />
                    <td class="border-top" v-text="currency(r.type === 'cancel' ? -r.total : r.total, 'USD')"/>
                    <td class="text-left text-muted small pl-3">total</td>
                  </tr>
                </table>

                <template v-else>
                  {{ currency(r.type === 'cancel' ? -r.total : r.total, 'USD') }}
                </template>
              </td>

              <td class="text-right">
                {{ r.reservation_id }}
              </td>
              <td class="text-right">
                <a v-if="r.inquiry" :href="r.inquiry.url">
                  <Component :is="r.isCancelled ? 's' : 'span'">
                    {{ r.inquiry.number }}
                  </Component>
                </a>
              </td>
              <td v-if="!hideProduct" class="text-right">
                <template v-if="r.product.id">
                  <a :href="r.product.url">
                    {{ r.product.id }} /
                  </a>
                </template> {{ r.product.name }}
              </td>
            </template>

            <td class="text-right">
              <button
                  class="btn btn-xxs btn-default"
                  type="button"
                  @click="showDetails(r.url)"
              >
                Details
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <UiPagination
          v-if="totalEntries > entries.length"
          v-model="currentPage"
          :total-entries="totalEntries"
          :per-page="perPage"
      />

      <BookingReservationModal ref="modal"/>
    </AsyncLoader>
  </UiCard>
</template>

<script>
import UiCard from "../../../components/UiCard.vue"
import UiPagination from "../../../components/UiPagination.vue"
import AsyncLoader from "../../AsyncLoader.vue"
import BookingReservationModal from "./BookingReservationModal.vue"
import { Reservation } from "./reservation"
import ReservationBadge from "./ReservationBadge.vue"
import { currency } from "../../CurrencyFormatter"

export default {
  components: {
    UiCard,
    AsyncLoader,
    UiPagination,
    BookingReservationModal,
    ReservationBadge,
  },

  props: {
    title:       { type: String, default: "Booking Notifications" },
    url:         { type: String, required: true },
    compact:     { type: Boolean, default: false },
    hideProduct: { type: Boolean, default: false },
  },

  data() {
    return {
      entries:      [],
      totalEntries: 0,
      currentPage:  1,
      perPage:      15,
      expandPrices: false,
    }
  },

  computed: {
    paginationUrl() {
      const url = new URL(this.url, document.baseURI)
      url.searchParams.set("page", `${this.currentPage}`)
      return url.toString()
    },
  },

  methods: {
    currency,

    onData({ entries, pagination: { page, total, per } }) {
      this.entries = entries.map(ent => new Reservation(ent))
      this.totalEntries = total
      this.perPage = per
      this.currentPage = page
    },

    showDetails(url) {
      this.$refs.modal.showModal(url)
    },
  },
}
</script>
