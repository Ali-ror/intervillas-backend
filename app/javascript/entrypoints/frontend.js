import "../lib/bootstrap"
import "../lib/load-i18n"
import "../lib/load-rails"

import Vue from "vue"
Vue.config.productionTip = false

import "../intervillas-drp/index"
import "../facet-search/index"
import "../header-search/index"
import "../villas-list/index"
import "../bsp1-hosted-iframe-form/index"
import "../header"

import { VueMasonryPlugin } from "vue-masonry"
Vue.use(VueMasonryPlugin)

import { Carousel, Slide } from "@jambonn/vue-concise-carousel"
Vue.component("Carousel", Carousel)
Vue.component("Slide", Slide)

import VModal from "vue-js-modal"
Vue.use(VModal, { componentName: "VModal" })

import VillaReviews from "../frontend/VillaReviews.vue"
Vue.component("VillaReviews", VillaReviews)

import Testimonials from "../frontend/Testimonials.vue"
Vue.component("IntervillasTestimonials", Testimonials)

import Gallery from "../frontend/Gallery.vue"
Vue.component("IntervillasGallery", Gallery)

import Panoramas from "../frontend/Panoramas.vue"
Vue.component("IntervillasPanoramas", Panoramas)

import Videos from "../frontend/Videos.vue"
Vue.component("IntervillasVideos", Videos)

import PaymentProgress from "../bsp1-hosted-iframe-form/PaymentProgress.vue"
Vue.component("PaymentProgress", PaymentProgress)

import VillaMap from "../frontend/map/VillaMap.vue"
Vue.component("VillaMap", VillaMap)

import OverviewMap from "../frontend/map/OverviewMap.vue"
Vue.component("OverviewMap", OverviewMap)

import LazyApplet from "../frontend/LazyApplet.vue"
Vue.component("LazyApplet", LazyApplet)

import ContactForm from "../frontend/ContactForm.vue"
Vue.component("ContactForm", ContactForm)

import LocalizationSelect from "../frontend/LocalizationSelect.vue"
Vue.component("LocalizationSelect", LocalizationSelect)

import NewsletterSignupButton from "../frontend/newsletter/NewsletterSignupButton.vue"
Vue.component("NewsletterSignupButton", NewsletterSignupButton)

import LiveChat from "../frontend/LiveChat.vue"
Vue.component("LiveChat", LiveChat)

import ClearingTable from "../frontend/ReservationForm/ClearingTable.vue"
Vue.component("ClearingTable", ClearingTable)

import ReservationForm from "../frontend/ReservationForm/ReservationForm.vue"
Vue.component("ReservationForm", ReservationForm)

import BoatBooking from "../frontend/BoatBooking/BoatBooking.vue"
Vue.component("BoatBooking", BoatBooking)

import PriceTable from "../admin/PriceTable/PriceTable.vue"
import PriceTableStandalone from "../frontend/PriceTableStandalone.vue"
import "../legacy"

import ReadMoreWrapper from "../frontend/ReadMoreWrapper/ReadMoreWrapper.vue"
Vue.component("ReadMoreWrapper", ReadMoreWrapper)

import CustomerFormMainTenant from "../frontend/CustomerFormMainTenant.vue"
Vue.component("CustomerFormMainTenant", CustomerFormMainTenant)

document.addEventListener("DOMContentLoaded", () => {
  const priceTableNode = document.querySelector("price-table")
  if (priceTableNode) {
    const vm = new Vue(PriceTable)
    vm.readOnly = true
    vm.currency = priceTableNode.getAttribute("currency")

    vm.$mount(priceTableNode)
  }

  const priceTableStandalone = document.querySelector("price-table-standalone")
  if (priceTableStandalone) {
    new Vue(PriceTableStandalone).$mount(priceTableStandalone)
  }

  document.querySelectorAll(".applet").forEach(el => {
    new Vue({ el, name: el.getAttribute("name") })
  })

  const appEl = document.querySelector("#app")
  if (appEl) {
    new Vue({ el: appEl, name: appEl.getAttribute("name") })
  }
})
