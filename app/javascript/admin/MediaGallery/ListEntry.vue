<template>
  <div
      class="img-thumbnail"
      :title="fullFilename"
  >
    <div v-if="medium.type !== 'upload'" class="quick-actions small">
      <a
          href="#"
          :disabled="saving"
          @click.prevent="toggleActive"
      >
        <i class="fa" :class="medium.active ? 'fa-toggle-on' : 'fa-toggle-off'" />
        {{ medium.active ? "aktiv" : "inaktiv" }}
      </a>

      <a
          href="#"
          :disabled="saving"
          @click.prevent="$emit('edit')"
      >
        <i class="fa fa-pencil" />
        bearbeiten
      </a>
    </div>

    <div
        class="list-thumb"
        :class="{ 'recent-upload': medium.recentUpload }"
        :title="medium.recentUpload ? 'vor Kurzem hochgeladen' : null"
        @click.prevent="$emit('edit')"
    >
      <ProgressPlaceholder
          v-if="medium.type === 'upload'"
          :upload="medium"
          :width="thumbnailWidth"
          :height="thumbnailHeight"
      />

      <img
          v-else-if="medium.type === 'tour'"
          src="./tour-nopreview.png"
          :width="thumbnailWidth"
          :height="thumbnailHeight"
      >

      <img
          v-else-if="medium.preview_url"
          :src="medium.thumbnail_url"
          :width="thumbnailWidth"
          :height="thumbnailHeight"
      >
    </div>

    <div class="handle">
      <div class="pull-right">
        <i
            v-if="!medium.active"
            class="fa fa-eye-slash"
            :title="medium.active ? null : 'Bild nicht aktiv'"
        />
        <span
            class="ml-1 fi fi-de"
            :class="{ 'fi-disabled': !hasDeDescr }"
            :title="deDescrTitle"
        />
        <span
            class="ml-1 fi fi-us"
            :class="{ 'fi-disabled': !hasEnDescr }"
            :title="enDescrTitle"
        />
      </div>
      <i class="fa fa-arrows" />
    </div>
  </div>
</template>

<script>
import "./tour-nopreview.png"
import { thumbnailWidth, thumbnailHeight } from "./config"
import ProgressPlaceholder from "./ProgressPlaceholder.vue"
import Utils from "../../intervillas-drp/utils"

export default {
  components: {
    ProgressPlaceholder,
  },

  props: {
    medium: { type: Object, required: true },
  },

  data() {
    return {
      saving: false,
      thumbnailWidth,
      thumbnailHeight,
    }
  },

  computed: {
    hasDeDescr() {
      return !!this.medium.de_description
    },
    deDescrTitle() {
      return `dt. Beschreibung ${this.hasDeDescr ? "vorhanden" : "fehlt"}`
    },
    hasEnDescr() {
      return !!this.medium.en_description
    },
    enDescrTitle() {
      return `en. Beschreibung ${this.hasEnDescr ? "vorhanden" : "fehlt"}`
    },
    fullFilename() {
      return `${this.medium.filename}.${this.medium.extname}`
    },
  },

  methods: {
    toggleActive() {
      this.saving = true
      const payload = {
        active: !this.medium.active,
      }
      Utils.putJSON(this.medium.url, { medium: payload }).then(data => {
        this.saving = false
        this.$emit("updated", data)
      })
    },
  },
}
</script>

<style>
  .img-thumbnail {
    position: relative;
    overflow: hidden;
  }
  .quick-actions {
    position: absolute;
    top: -50px;
    left: 0;
    right: 0;
    transition: top 200ms;
    padding: 6px;
    background-color: rgba(255, 255, 255, 0.9);
    z-index: 6;
  }
  .quick-actions a {
    display: block;
    text-align: center;
  }
  .quick-actions a + a {
    margin-top: 6px;
  }
  .img-thumbnail:hover .quick-actions {
    top: 0;
  }

  .fi-disabled {
    opacity: 0.25;
  }

  .list-thumb {
    z-index: 5;
  }
  .list-thumb.recent-upload {
    position: relative;
  }
  .list-thumb.recent-upload::before {
    content: "";
    border: 30px solid transparent;
    border-bottom-color: #416d0a;

    position: absolute;
    top: -30px;
    right: -30px;
    transform: rotate(45deg);
    z-index: 2;
  }
  .list-thumb.recent-upload::after {
    display: inline-block;
    text-align: center;
    font-family: FontAwesome;
    color: #fff;
    content: "\f00c"; /* fa-check */

    position: absolute;
    top: 0;
    right: 0;
    z-index: 3;
    line-height: 25px;
    width: 25px;
  }
</style>
