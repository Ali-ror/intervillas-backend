import Vue from "vue"

import HeaderSearchInline from "./HeaderSearchInline.vue"
import HeaderSearchPopup from "./HeaderSearchPopup.vue"
import Utils from "../intervillas-drp/utils"
import Fuse from "fuse.js"

const bus = new Vue({
  name: "HeaderSearchBus",

  data: {
    sourceURL: "/api/villas/prefetch.json",

    // non-reactive data:
    // villaData:  Promise<Array>,
    // _fuse: Promise<fuse>,
  },

  methods: {
    search(str) {
      return this.engine().then(engine => {
        return engine.search(str).slice(0, 10)
      })
    },

    engine() {
      if (this._fuse) {
        return Promise.resolve(this._fuse)
      }
      return new Promise((resolve, _reject) => {
        this.villas().then(villas => {
          this._fuse = new Fuse(villas, {
            keys:               ["name"],
            findAllMatches:     true,
            minMatchCharLength: 2,
          })
          resolve(this._fuse)
        })
      })
    },

    villas() {
      if (this.villaData) {
        return Promise.resolve(this.villaData)
      }
      return new Promise((resolve, _reject) => {
        Utils.fetchJSON(this.sourceURL).then(data => {
          this.villaData = data
          resolve(this.villaData)
        })
      })
    },
  },
})

const elems = {
  "header-search-inline": HeaderSearchInline,
  "header-search-popup":  HeaderSearchPopup,
}

document.addEventListener("DOMContentLoaded", _ev => {
  Object.entries(elems).forEach(([selector, component]) => {
    document.querySelectorAll(selector).forEach(node => {
      const inst = new Vue(component).$mount(node)
      inst.$on("search", input => {
        bus.search(input).then(results => {
          inst.villas = results
        })
      })
    })
  })
})
