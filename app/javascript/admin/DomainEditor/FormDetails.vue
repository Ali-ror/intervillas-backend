<template>
  <div class="details" :class="{ 'details-open': open }">
    <div class="form-control-static detail-header" @click="$emit('toggle', !open)">
      <i class="fa fa-fw" :class="open ? 'fa-caret-down' : 'fa-caret-right'" />
      {{ title }}
    </div>

    <slot v-if="open" />
  </div>
</template>

<script>
export default {
  props: {
    title: { type: String, required: true },
    open:  { type: Boolean, default: false },
  },
}
</script>

<style>
.form-control-static.detail-header {
  outline: none;
  cursor: pointer;
  margin-bottom: 6px;
}
</style>
