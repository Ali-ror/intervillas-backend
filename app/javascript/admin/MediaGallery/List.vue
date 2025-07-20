<template>
  <div class="media-gallery-list">
    <h2>
      {{ title }}

      <a
          href="#"
          class="close"
          title="Liste neu laden"
          @click.prevent="$emit('reload')"
      ><i class="fa fa-refresh" /></a>
    </h2>

    <div
        v-if="media.length === 0"
        class="alert alert-warning"
    >
      Noch keine Inhalte hochgeladen.
    </div>

    <VueDraggable
        v-else
        ref="list"
        v-model="sortableMedia"
        v-bind="dragOptions"
        class="media-list"
        :class="{ editing: !!editId }"
        :style="{ maxHeight: listMaxHeight }"
        @end="$emit('reorder')"
    >
      <ListEntry
          v-for="medium in sortableMedia"
          :key="medium.id"
          class="media-list-item"
          :class="mediaClasses(medium)"
          :medium="medium"
          @edit="medium.id === editId ? $emit('close') : $emit('edit', medium.id)"
          @updated="$emit('updated', medium.id, $event)"
      />
    </VueDraggable>
  </div>
</template>

<script>
import VueDraggable from "vuedraggable"
import ListEntry from "./ListEntry.vue"

export default {
  components: {
    VueDraggable,
    ListEntry,
  },

  props: {
    title:  { type: String, default: "Bilder" },
    media:  { type: Array, default: () => ([]) },
    editId: { type: null, default: null },
  },

  data() {
    return {
      dragOptions:   {},
      listMaxHeight: `${0.85 * window.innerHeight}px`,
    }
  },

  computed: {
    mediaByID() {
      const byID = {}
      for (let i = 0, len = this.media.length; i < len; ++i) {
        const medium = this.media[i]
        byID[medium.id] = medium
      }
      return byID
    },

    sortableMedia: {
      get() {
        return this.media.slice(0)
      },

      set(v) {
        for (let i = 0, len = v.length; i < len; ++i) {
          const medium = v[i]
          this.mediaByID[medium.id].position = i
        }
      },
    },
  },

  methods: {
    mediaClasses(medium) {
      const css = {
        inactive: !medium.active,
        editing:  medium.id === this.editId,
      }
      css[`medium-${medium.type}-${medium.id}`] = true
      return css
    },
  },
}
</script>

<style>
  .media-list {
    margin-left: -6px;
    margin-right: -6px;
    display: flex;
    flex-flow: row wrap;
    align-items: center;
    justify-content: flex-start;
  }
  .media-list::after {
    content: "";
    flex: auto;
  }

  .media-list .media-list-item {
    cursor: pointer;
    margin: 4px;
    border-width: 2px
  }
  a.media-list-item {
    color: inherit
  }
  a.media-list-item:hover {
    color: inherit;
    border-color: #75c5cf;
  }
  .media-list.editing .media-list-item:not(.editing) {
    opacity: 0.5;
  }
  .media-list .media-list-item.editing {
    border-color: #75c5cf;
  }
  .media-list .media-list-item.inactive:not(.editing) img {
    opacity: 0.6;
    filter: saturate(0);
  }
  .media-list-item.sortable-ghost {
    border-color: #75c5cf;
    background-color: #75c5cf;
  }
  .media-list-item.sortable-ghost > * {
    visibility: hidden;
  }
</style>
