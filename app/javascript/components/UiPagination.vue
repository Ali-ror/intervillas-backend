<template>
  <nav class="d-flex justify-content-center">
    <ul class="pagination">
      <li
          v-for="p in pages"
          :key="p.id"
          :class="{
            disabled: p.disabled,
            active: p.active,
          }"
      >
        <span
            v-if="p.disabled"
            class="text-muted"
            v-text="p.label"
        />
        <a
            v-else
            :href="`#page-${p.page}`"
            @click.prevent="$emit('input', p.page)"
            v-text="p.label"
        />
      </li>
    </ul>
  </nav>
</template>

<script>

const [FIRST, PREV, SKIP, NEXT, LAST] = ["«", "‹", "…", "›", "»"]

export default {
  props: {
    totalEntries: { type: Number, required: true },
    value:        { type: Number, default: 1 }, // v-model
    perPage:      { type: Number, default: 30 },
    surround:     { type: Number, default: 2 }, // number of pagers before/after current page (i.e. window size = 1 + 2*surround)
  },

  computed: {
    totalPages() {
      const n = Math.ceil(this.totalEntries / this.perPage)
      return n < 1 ? 1 : n
    },

    pages() {
      const { value, surround, totalPages } = this,
            minPage = Math.max(value - surround, 1),
            maxPage = Math.min(value + surround, totalPages)

      const pages = []
      pages.push(
        { id: "first", page: 1, label: FIRST, disabled: value === 1 },
        { id: "prev", page: value - 1, label: PREV, disabled: value === 1 },
      )

      if (minPage > 1) {
        pages.push({ id: "front", label: SKIP, disabled: true })
      }
      for (let page = minPage; page <= maxPage; ++page) {
        pages.push({ page, label: page, active: page === value })
      }
      if (maxPage < totalPages) {
        pages.push({ id: "back", label: SKIP, disabled: true })
      }

      pages.push(
        { page: value + 1, label: NEXT, disabled: value >= totalPages },
        { page: totalPages, label: LAST, disabled: value >= totalPages },
      )
      return pages
    },
  },
}
</script>
