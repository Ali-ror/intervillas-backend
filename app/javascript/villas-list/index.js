import Vue from "vue"
import VillasList from "./VillasList.vue"

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("villas-list").forEach(node => {
    new Vue(VillasList).$mount(node)
  })
})
