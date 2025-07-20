<template>
  <div class="header-search-inline">
    <div class="dropdown" :class="{ 'open': input && villas && villas.length }">
      <form class="form-inline" @submit.prevent>
        <input
            id="header-search-input"
            v-model="input"
            class="form-control"
            :placeholder="translate('header_search.placeholder')"
            autocomplete="off"
            spellcheck="false"
            type="text"
            @keyup.down="setActive(1)"
            @keyup.up="setActive(-1)"
            @keyup.esc="clear()"
            @keyup.enter="followActive()"
        >
        <i class="fa fa-search" />
      </form>
      <ul class="dropdown-menu">
        <li
            v-for="(v, idx) of villas"
            :key="v.refIndex"
            :class="{ 'active': idx === activeIndex }"
            @mouseenter="activeIndex = idx"
        >
          <a
              :href="v.item.path"
              v-text="v.item.name"
          />
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import BaseMixin from "./BaseMixin"
import { translate } from "@digineo/vue-translate"

export default {
  name: "HeaderSearchInline",

  mixins: [BaseMixin],

  methods: {
    translate,
  },
}
</script>

<style lang="scss" scoped>
  form {
    position: relative;
  }
  input {
    display: inline;
    padding-right: 3em;
  }
  input ~ i {
    position: absolute;
    right: 1em;
    line-height: 32px;
    top: 0;
  }
</style>
