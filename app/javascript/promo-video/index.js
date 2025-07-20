import Vue from "vue"
import PromoVideo from "./promo-video.vue"

document.addEventListener("DOMContentLoaded", () => {
  const node = document.querySelector("promo-video")
  if (node) {
    new Vue(PromoVideo).$mount(node)
  }
})
