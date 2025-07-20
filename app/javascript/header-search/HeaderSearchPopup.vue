<template>
  <a
      class="header-search-popup"
      href="#"
      @click.prevent="toggleModal()"
  >
    <i class="fa fa-fw fa-search" />
    <span class="hidden-sm">
      {{ translate("header_search.menu") }}
    </span>

    <div
        id="header-search-popup-modal"
        class="modal mt-3"
        @click.stop
    >
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <a
                href="#"
                class="pull-right"
                @click.prevent="close"
            >
              <i class="fa fa-times fa-lg" />
            </a>
            <h4 class="modal-title">
              {{ translate("header_search.menu") }}
            </h4>
          </div>
          <div class="modal-body">
            <form style="margin-top:0">
              <input
                  v-model="input"
                  class="form-control input-lg"
                  :placeholder="translate('header_search.placeholder')"
                  type="text"
                  @keyup.down="setActive(1)"
                  @keyup.up="setActive(-1)"
                  @keyup.esc="input === '' ? toggleModal() : clear()"
                  @keyup.enter="followActive()"
              >
            </form>
            <div class="list-group">
              <a
                  v-for="(v, idx) in villas"
                  :key="v.refIndex"
                  class="list-group-item"
                  :class="{ 'active': idx === activeIndex }"
                  :href="v.item.path"
                  @mouseenter="activeIndex = idx"
                  v-text="v.item.name"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </a>
</template>

<script>
import BaseMixin from "./BaseMixin"
import { translate } from "@digineo/vue-translate"

export default {
  name: "HeaderSearchPopup",

  mixins: [BaseMixin],

  mounted() {
    this.modal = $("#header-search-popup-modal").modal({
      backdrop: false,
      keyboard: false,
      show:     false,
    })

    this.modal.on("shown.bs.modal", function() {
      $("input", this).focus()
    }).on("hidden.bs.modal", () => {
      this.clear()
    })
  },

  beforeDestroy() {
    this.modal.hide()
    this.modal = null
  },

  methods: {
    translate,

    close() {
      this.modal.modal("hide")
    },

    toggleModal() {
      this.modal.modal("toggle")
    },
  },
}
</script>
