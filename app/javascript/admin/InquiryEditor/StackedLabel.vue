<template>
  <div class="col-md-4">
    <label :for="id" class="control-label">
      {{ label }}

      <svg
          v-if="required"
          height="10"
          width="10"
      >
        <path
            fill="#ff9900"
            stroke="none"
            d="M7.5 0v10l-5 -5z"
        />
      </svg>
    </label>

    <slot />
  </div>
</template>

<script>
export default {
  name: "StackedLabel",

  props: {
    id:       { type: String, required: true },
    required: { type: Boolean, default: false },
    label:    { type: String, required: true },
  },
}
</script>
