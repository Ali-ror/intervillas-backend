<template>
  <div>
    <div class="row">
      <section class="col-sm-12 col-md-8">
        <template v-if="selectedBoat">
          <h2 class="lined-heading">
            <span v-text="selectedBoat.model" />
          </h2>
          <BoatDetails :boat="selectedBoat">
            <Gallery
                :slides="selectedBoat.gallery"
                dots
                no-fullscreen
            />
          </BoatDetails>
        </template>
        <slot
            v-else
            name="teaser"
            :open="showSelection"
        />

        <div class="row my-5">
          <div class="col-sm-6 col-md-4 col-md-offset-2">
            <button
                class="btn btn-block"
                :class="{
                  active: showSelection,
                  'btn-primary': !showSelection,
                  'btn-default': showSelection,
                }"
                :disabled="selectedBoat"
                @click.prevent="showSelection = !showSelection"
            >
              <i class="fa" :class="showSelection ? 'fa-eye-slash' : 'fa-eye'" />
              {{ t('show_boats') }}
            </button>
          </div>

          <div class="col-sm-6 col-md-4">
            <button
                v-if="selectedBoat"
                class="btn btn-default btn-block"
                @click.prevent="selectedBoat = null"
            >
              <i class="fa fa-times" />
              {{ t('remove_boat') }}
            </button>
            <a
                v-else
                class="btn btn-default btn-block"
                :href="`/inquiries/${token}/customer`"
            >
              <i class="fa fa-arrow-right" />
              {{ t('continue_without_boat') }}
            </a>
          </div>
        </div>
      </section>

      <div class="col-sm-12 col-md-4">
        <ReservationForm
            :boat="selectedBoat"
            :arrival="arrivalDate"
            :departure="departureDate"
            :token="token"
            :currency="currency"
        />

        <slot v-if="showSelection && selectedBoat" name="fineprint" />
      </div>
    </div>

    <template v-if="showSelection">
      <slot name="listing" :skip-note="boats.length === 0" />

      <p
          v-if="availableBoats.length === 0"
          class="well"
          v-text="t('no_boats_available')"
      />

      <section v-else class="room-grid">
        <BoatTeaser
            v-for="boat in availableBoats"
            :key="boat.id"
            :boat="boat"
            @show-details="$refs.modal.show(boat)"
        />
      </section>
    </template>

    <BoatDetailsModal
        ref="modal"
        :boats="availableBoats"
        @selected="selectBoat"
    />
  </div>
</template>

<script>
import Gallery from "../Gallery.vue"
import BoatDetailsModal from "./BoatDetailsModal.vue"
import BoatTeaser from "./BoatTeaser.vue"
import BoatDetails from "./BoatDetails.vue"
import ReservationForm from "./ReservationForm.vue"
import { railsClient as api } from "../../intervillas-drp/utils"
import { annotateAvailability } from "./availability"
import { makeDate } from "../../lib/DateFormatter"
import { translate } from "@digineo/vue-translate"
import { setHours } from "date-fns"
const t = key => translate(key, { scope: "boat_booking" })

export default {
  components: {
    Gallery,
    BoatDetailsModal,
    BoatTeaser,
    ReservationForm,
    BoatDetails,
  },

  props: {
    token:     { type: String, required: true },
    currency:  { type: String, required: true, validate: v => ["EUR", "USD"].includes(v) },
    arrival:   { type: String, required: true },
    departure: { type: String, required: true },
  },

  data() {
    return {
      showSelection: false,

      boats:        [],
      selectedBoat: null,
    }
  },

  computed: {
    arrivalDate() {
      return setHours(makeDate(this.arrival), 16)
    },

    departureDate() {
      return setHours(makeDate(this.departure), 8)
    },

    availableBoats() {
      return this.boats.filter(b => b.availability.key !== "none")
    },
  },

  async mounted() {
    const { data } = await api.get(`/api/inquiries/${this.token}/boats.json`)
    this.boats = annotateAvailability(data, {
      arrival:   this.arrivalDate,
      departure: this.departureDate,
    })
  },

  methods: {
    t,

    selectBoat(boat) {
      this.selectedBoat = boat
      window.scrollTo({ top: 0 })
    },
  },
}
</script>
