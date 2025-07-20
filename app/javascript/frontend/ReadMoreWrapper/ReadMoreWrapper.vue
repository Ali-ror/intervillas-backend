<template>
  <div class="read-more-wrapper" :class="{ 'read-more': !open }">
    <div
        ref="content"
        class="read-more-content"
        :style="{ height: contentHeight }"
    >
      <slot />
    </div>

    <div class="read-more-control">
      <button
          class="btn btn-xxs btn-default"
          @click.prevent="open = true"
          v-text="label"
      />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    label:  { type: String, required: true },
    height: { type: [String, Number], required: true },
  },

  data() {
    return {
      open: false,
    }
  },

  computed: {
    contentHeight() {
      return this.open ? "auto" : `${this.height}px`
    },
  },
}
</script>

<style lang="scss">
  .read-more-wrapper {
    position: relative;

    .read-more-content {
      overflow-y: hidden;
    }

    .read-more-control {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 0px;

      display: flex;
      justify-content: center;
      align-items: flex-end;
      overflow: hidden;
    }

    &.read-more {
      .read-more-control {
        top: 0;
        height: auto;
        background: linear-gradient(0deg, #fff 0px, #fff 33px, #fff0 75px, #fff0 100%);

        button::after {
          content: "";
          display: block;
          position: absolute;
          top: 0;
          bottom: 0;
          left: 0;
          right: 0;
        }
      }
    }
  }
</style>
