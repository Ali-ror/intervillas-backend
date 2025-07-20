import Vue from "vue"
import Bsp1HostedIframeForm from "./Bsp1HostedIframeForm.vue"

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("bsp1-hosted-iframe-form").forEach(node => {
    new Vue(Bsp1HostedIframeForm).$mount(node)
  })
})
