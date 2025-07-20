<template>
  <div class="text-center">
    <div class="visible-md visible-lg">
      <template v-if="items.length > 1">
        <a
            v-for="(it, i) of items"
            :key="i"
            :href="it.url"
            class="btn btn-panorama"
            :class="active === i ? 'btn-primary' : 'btn-default'"
            @click.prevent="active = i"
            v-text="it.name"
        />
      </template>

      <div id="panorama" class="mt-4">
        <iframe
            :src="items[active].url"
            width="100%"
            height="500"
            frameborder="0"
            allowfullscreen
        />
      </div>
    </div>

    <div class="visible-xs visible-sm">
      <a
          v-for="(it, i) of items"
          :key="i"
          :href="it.url"
          class="btn btn-default btn-panorama"
          @click.prevent="showModal(i)"
          v-text="it.name"
      />

      <VModal
          name="panorama"
          class="bg-dark"
          width="95%"
          height="90%"
          @before-close="onCloseModal"
      >
        <template #top-right>
          <button type="button" @click.prevent="closeModal">
            <i class="fa fa-fw fa-lg fa-times" />
          </button>
        </template>

        <iframe
            :src="items[active].url"
            width="100%"
            height="100%"
            frameborder="0"
            allowfullscreen
        />
      </VModal>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    items: { type: Array, required: true },
  },

  data() {
    return {
      active: 0,
    }
  },

  methods: {
    showModal(i) {
      this.active = i
      document.querySelector("body").style.overflow = "hidden"
      this.$modal.show("panorama")
    },

    closeModal() {
      this.$modal.hide("panorama")
    },

    onCloseModal() {
      document.querySelector("body").style.overflow = ""
    },
  },
}
</script>

<style lang="scss">
  a.btn-panorama {
    margin: 1ex;
  }

  .v--modal-overlay[data-modal="panorama"] {
    background: rgba(0, 0, 0, 0.75);
    z-index: 10000;

    .v--modal {
      background-color: #000 !important;

      iframe {
        width:  100%;
        height: 100%;
      }
    }

    .v--modal-top-right {
      z-index: 1;

      button {
        margin:         12px;
        height:         50px;
        width:          50px;
        line-height:    50px;
        border-radius:  50%;
        background:     #333;
        border:         none;
        color:          #fff;
        opacity:        0.75;

        &:hover {
          opacity: 1;
        }
      }
    }
  }
</style>
