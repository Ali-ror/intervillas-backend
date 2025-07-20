import "../lib/bootstrap"
import "../lib/load-i18n"
import "../lib/load-rails"

import Vue from "vue"
Vue.config.productionTip = false

import VueRouter from "vue-router"
Vue.use(VueRouter)

import { setup } from "@digineo/vue-translate"
import locales from "../admin/i18n"
setup(Vue, locales)

import "../intervillas-drp"

import VModal from "vue-js-modal"
Vue.use(VModal, { componentName: "VModal" })

import BoatListing from "../admin/BoatListing.vue"
import BoatPriceEditor from "../admin/BoatPriceEditor.vue"
import BookingEditor from "../admin/InquiryEditor/BookingEditor.vue"
import CancelInquiryModal from "../admin/cancellation/CancelInquiryModal.vue"
import CancellationEditor from "../admin/InquiryEditor/CancellationEditor.vue"
import DomainEditor from "../admin/DomainEditor/DomainEditor.vue"
import GridSelect from "../admin/GridSelect.vue"
import HighSeasonRangePicker from "../admin/HighSeasonRangePicker.vue"
import InquiryEditor from "../admin/InquiryEditor/InquiryEditor.vue"
import CustomerStateInfo from "../admin/InquiryEditor/CustomerStateInfo.vue"
import MediaGallery from "../admin/MediaGallery.vue"
import MyBookingPalManager from "../admin/MyBookingPal/Manager.vue"
import MyBookingPalProductDashboard from "../admin/MyBookingPal/ProductDashboard.vue"
import MyBookingPalPushNotifications from "../admin/MyBookingPal/PushNotifications.vue"
import MyBookingPalRequestLogs from "../admin/MyBookingPal/RequestLogs.vue"
import MyBookingPalReservations from "../admin/MyBookingPal/reservations/BookingReservations.vue"
import MyBookingPalUpdateProgressBar from "../admin/MyBookingPal/products/UpdateProgressBar.vue"
import MyBookingPalPreFlightChecks from "../admin/MyBookingPal/products/PreFlightChecks.vue"
import OccupancyCollisions from "../admin/OccupancyCollisions.vue"
import PaymentDetailToggle from "../admin/PaymentDetailToggle.vue"
import PriceTable from "../admin/PriceTable/PriceTable.vue"
import Sales from "../admin/Sales.vue"
import SidebarDetails from "../admin/InquiryEditor/Sidebar/Details.vue"
import SnippetEditor from "../admin/SnippetEditor.vue"
import StatsComparison from "../admin/stats/StatsComparison.vue"
import StatsFilter from "../admin/StatsFilter.vue"
import ToggleActive from "../admin/ToggleActive.vue"
import UncancelInquiryModal from "../admin/cancellation/UncancelInquiryModal.vue"
import VillaEditor from "../admin/VillaEditor.vue"
import UiSelectInput from "../components/UiSelectInput.vue"

Vue.component("AdminBoatListing", BoatListing)
Vue.component("AdminBookingEditor", BookingEditor)
Vue.component("AdminCancellationEditor", CancellationEditor)
Vue.component("AdminDomainEditor", DomainEditor)
Vue.component("AdminGridSelect", GridSelect)
Vue.component("AdminInquiryEditor", InquiryEditor)
Vue.component("AdminCustomerStateInfo", CustomerStateInfo)
Vue.component("AdminMediaGallery", MediaGallery)
Vue.component("AdminOccupancyCollisions", OccupancyCollisions)
Vue.component("AdminSales", Sales)
Vue.component("AdminStatsFilter", StatsFilter)
Vue.component("AdminSnippetEditor", SnippetEditor)
Vue.component("BoatPriceEditor", BoatPriceEditor)
Vue.component("CancelInquiryModal", CancelInquiryModal)
Vue.component("HighSeasonRangePicker", HighSeasonRangePicker)
Vue.component("MyBookingPalManager", MyBookingPalManager)
Vue.component("MyBookingPalProductDashboard", MyBookingPalProductDashboard)
Vue.component("MyBookingPalPushNotifications", MyBookingPalPushNotifications)
Vue.component("MyBookingPalRequestLogs", MyBookingPalRequestLogs)
Vue.component("MyBookingPalReservations", MyBookingPalReservations)
Vue.component("MyBookingPalUpdateProgressBar", MyBookingPalUpdateProgressBar)
Vue.component("MyBookingPalPreFlightChecks", MyBookingPalPreFlightChecks)
Vue.component("PaymentDetailToggle", PaymentDetailToggle)
Vue.component("PriceTable", PriceTable)
Vue.component("SidebarDetails", SidebarDetails)
Vue.component("StatsComparison", StatsComparison)
Vue.component("ToggleActive", ToggleActive)
Vue.component("UncancelInquiryModal", UncancelInquiryModal)
Vue.component("VillaEditor", VillaEditor)
Vue.component("UiSelectInput", UiSelectInput)

import "../admin/clipboard"
import "../legacy/admin"
import "../stylesheets/admin/bootstrap.sass"

document.addEventListener("DOMContentLoaded", () => {
  const el = document.getElementById("intervillas-app")
  if (el) {
    new Vue({ el, name: "IntervillasAdmin" })
  }
})
