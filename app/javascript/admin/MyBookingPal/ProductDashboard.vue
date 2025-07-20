<template>
  <div>
    <div class="row">
      <div class="col-sm-6">
        <UiCard heading="General Settings">
          <p>
            MyBookingPal ID: <code>{{ foreignId || "—" }}</code>.
          </p>
          <p>
            For (some) customization, see <a :href="`/admin/villas/${villaId}/edit#/additional-props`">
              <i class="fa fa-arrow-right" />
              Addtitional Properties
            </a> on the Villa edit page.
          </p>
        </UiCard>
      </div>

      <div class="col-sm-6">
        <UiCard heading="Local Validations">
          <PreFlightChecks :checks="checks" />
        </UiCard>
      </div>
    </div>

    <UpdateProgress :url="url"/>
    <ImageImports :url="`${url}/image_imports`"/>
    <ProductStatus :url="`${url}/life_cycles`"/>
    <BookingReservations :url="`${url}/reservations`" :hide-product="true"/>
    <DeleteProduct :url="url"/>
  </div>
</template>

<script>
import BookingReservations from "./reservations/BookingReservations.vue"
import DeleteProduct from "./products/DeleteProduct.vue"
import ImageImports from "./products/ImageImports.vue"
import ProductStatus from "./products/ProductStatus.vue"
import UiCard from "../../components/UiCard.vue"
import UpdateProgress from "./products/UpdateProgress.vue"
import PreFlightChecks from "./products/PreFlightChecks.vue"

export default {
  components: {
    BookingReservations,
    DeleteProduct,
    ImageImports,
    ProductStatus,
    UiCard,
    UpdateProgress,
    PreFlightChecks,
  },

  props: {
    villaId:   { type: [String, Number], required: true },
    foreignId: { type: [String, Number], default: null },
    url:       { type: String, required: true },
    checks:    { type: Array, required: true },
  },
}
</script>
