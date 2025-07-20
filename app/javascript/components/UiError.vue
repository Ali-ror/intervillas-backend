<template>
  <div class="alert alert-danger">
    <i class="fa fa-exclamation-triangle pull-right" />
    <strong>Fehler:</strong> {{ errorMessage }}
  </div>
</template>

<script>
export default {
  props: {
    errorMessage: {},
  },
}
</script>
