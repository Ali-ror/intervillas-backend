<template>
  <div>
    {{ displayName }}

    <div v-if="emails?.length" class="small text-muted">
      {{ emails.join(", ") }}
    </div>
  </div>
</template>

<script>
export default {
  props: {
    id:     { type: Number, required: true },
    name:   { type: String, default: null },
    emails: { type: Array, default: () => ([]) },
  },

  computed: {
    displayName() {
      const { id, name } = this
      if (name && name.trim()) {
        return name.trim()
      }
      return `[Unbenannter Kontakt, ID ${id}]`
    },
  },
}
</script>
