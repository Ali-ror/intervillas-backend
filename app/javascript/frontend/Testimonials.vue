<template>
  <div class="testimonials">
    <Carousel ref="carousel" v-bind="options">
      <slot />
    </Carousel>
  </div>
</template>

<script>
export default {
  name: "IntervillasTestimonials",

  data() {
    return {
      options: {
        autoplay:                  false,
        adjustableHeight:          true,
        loop:                      true,
        navigationEnabled:         true, // we have custom controls
        navigationPrevLabel:       "<i class=\"fa fa-fw fa-chevron-left\"></i>",
        navigationNextLabel:       "<i class=\"fa fa-fw fa-chevron-right\"></i>",
        navigationClickTargetSize: 20,
        perPage:                   1,
        paginationEnabled:         false, // dots
      },
    }
  },
}
</script>

<style lang="scss">
.testimonials {
  $controls-width: 50px;

  margin: 0 $controls-width;

  &::before, &::after {
    content: " ";
    display: block;
  }

  .item > div {
    margin: 6px 12px;
  }

  .VueCarousel-navigation-button {
    color: #666 !important;

    &:hover, &:focus {
      color: #333 !important;
    }
  }
}
</style>
