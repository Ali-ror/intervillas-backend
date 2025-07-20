<template>
  <VModal
      name="boat-details"
      click-to-close
      :width="loading ? 250 : 782"
      :height="loading ? undefined : 'auto'"
      @closed="reset"
  >
    <div
        v-if="boat"
        class="panel panel-default d-flex flex-column m-0"
        style="max-height: 90vh"
    >
      <div class="panel-heading rounded-0 d-flex justify-content-center">
        <button
            v-if="boats.length > 1"
            class="btn btn-default"
            type="button"
            @click.prevent="gotoBoat(-1)"
        >
          <i class="fa fa-angle-double-left" />
          {{ t("prev_boat") }}
        </button>

        <h4
            class="panel-header mx-auto"
            v-text="boat.model"
        />

        <button
            v-if="boats.length > 1"
            class="btn btn-default"
            type="button"
            @click.prevent="gotoBoat(1)"
        >
          {{ t("next_boat") }}
          <i class="fa fa-angle-double-right" />
        </button>
      </div>

      <div v-if="loading" class="panel-body">
        <p class="text-center text-muted">
          <i class="fa fa-spinner fa-pulse fa-4x" />
        </p>
      </div>

      <div
          v-else
          class="panel-body flex-grow-1"
          style="overflow-y: auto"
      >
        <Gallery
            :slides="boat.gallery"
            dots
            no-fullscreen
        />
        <BoatDetails :boat="boat"/>
      </div>

      <div class="panel-footer d-flex justify-content-end gap-3">
        <button
            type="button"
            class="btn btn-default"
            @click="$modal.hide('boat-details')"
            v-text="t('cancel')"
        />
        <button
            type="button"
            class="btn btn-primary"
            @click="selectCurrentBoat"
            v-text="t('select')"
        />
      </div>
    </div>
  </VModal>
</template>

<script>
import Gallery from "../Gallery.vue"
import BoatDetails from "./BoatDetails.vue"
import { railsClient as api } from "../../intervillas-drp/utils"

import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "boat_booking.modal" })

const cache = new Map()

export default {
  components: {
    Gallery,
    BoatDetails,
  },

  props: {
    boats: { type: Array, default: () => ([]) },
  },

  data() {
    return {
      loading: false,
      boat:    null,
      index:   -1,
    }
  },

  methods: {
    t,

    selectCurrentBoat() {
      this.$emit("selected", this.boat)
      this.$modal.hide("boat-details")
    },

    gotoBoat(dir) {
      const { boats, index } = this,
            { length: n } = boats,
            idx = (n + index + dir) % n
      this.show(boats[idx])
    },

    async show(boat) {
      if (this.loading) {
        return
      }
      console.log(boat,'boats')
      this.loading = true
      this.boat = boat
      this.index = this.boats.findIndex(b => b.id === this.boat.id)
      this.$modal.show("boat-details")
      document.body.classList.add("fullscreen-boat-details")

      try {
        if (cache.has(boat.id)) {
          this.boat = cache.get(boat.id)
          return
        }
        console.log(boat, 'boat-detail')
        const { data } = await api.get(`/boats/${boat.id}.json`),
              clone = { ...boat, ...data }
        cache.set(boat.id, clone)
        this.boat = clone
        console.log(clone, 'boat-data')
      } finally {
        this.loading = false
      }
    },

    reset() {
      document.body.classList.remove("fullscreen-boat-details")
      this.loading = false
      this.boat = null
      this.index = -1
    },
  },
}
</script>

<style lang="scss">
  body.fullscreen-boat-details {
    overflow: hidden;

    #go-top {
      display: none;
    }
  }
</style>
