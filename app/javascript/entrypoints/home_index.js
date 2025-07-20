import Vue from "vue"
Vue.config.productionTip = false

import vOutsideClick from "@digineo/v-outside-click"
Vue.directive("outside-click", vOutsideClick)

import "../lib/load-i18n"
import "../facet-search/index"
import "../header-search/index"
import "../promo-video/index"
import "../legacy/starhotel/go-top"

import "../legacy/starhotel/digineo.core"
import "../legacy/analytics"

import "../lib/bootstrap"
import "../header"

import VModal from "vue-js-modal"
Vue.use(VModal, { componentName: "VModal" })

import { Carousel, Slide } from "@jambonn/vue-concise-carousel"
Vue.component("Carousel", Carousel)
Vue.component("Slide", Slide)

import ContactForm from "../frontend/ContactForm.vue"
Vue.component("ContactForm", ContactForm)

import Testimonials from "../frontend/Testimonials.vue"
Vue.component("IntervillasTestimonials", Testimonials)

import LocalizationSelect from "../frontend/LocalizationSelect.vue"
Vue.component("LocalizationSelect", LocalizationSelect)

import NewsletterSignupButton from "../frontend/newsletter/NewsletterSignupButton.vue"
Vue.component("NewsletterSignupButton", NewsletterSignupButton)

import LiveChat from "../frontend/LiveChat.vue"
Vue.component("LiveChat", LiveChat)

import WeatherForecast from "../frontend/Weather/WeatherForecast.vue"
Vue.component("WeatherForecast", WeatherForecast)

import HeroSlider from "../home_index/HeroSlider.vue"

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("florida-is-waiting-for-you").forEach(node => {
    new Vue(HeroSlider).$mount(node)
  })

  document.querySelectorAll(".applet").forEach(el => {
    new Vue({ el, name: el.getAttribute("name") })
  })
})
