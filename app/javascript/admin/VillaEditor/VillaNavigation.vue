<template>
  <aside class="col-sm-2 sidebar-left">
    <ul class="nav nav-pills nav-stacked">
      <RouterLink
          v-for="r in activeRoutes"
          :key="r.path"
          v-slot="{ href, navigate, isExactActive }"
          :to="{ path: r.path }"
          exact
          custom
      >
        <li :class="{ active: isExactActive }">
          <a
              :href="href"
              @click="navigate"
              @keypress.enter="navigate"
          >
            <i class="fa fa-fw" :class="r.meta.icon" />
            {{ navLabel(r.meta.i18nkey) }}
          </a>
        </li>
      </RouterLink>
    </ul>

    <div
        v-if="newRecord"
        class="well well-sm mt-2"
    >
      <em class="text-muted">
        Weitere Einstellungen sind erst nach dem Speichern möglich.
      </em>
    </div>

    <ul v-if="id || index" class="nav nav-pills nav-stacked">
      <li v-if="id">
        <a :href="`/villas/${id}`">
          <i class="fa fa-fw fa-eye" />
          {{ navLabel("show") }}
        </a>
      </li>

      <li v-if="index">
        <a :href="index">
          <i class="fa fa-fw fa-caret-left" />
          {{ navLabel("index") }}
        </a>
      </li>
    </ul>
  </aside>
</template>

<script>
import { translate } from "@digineo/vue-translate"

export default {
  props: {
    id:        { type: [String, Number], default: null }, // villa id
    newRecord: { type: Boolean, required: true },
    index:     { type: String, default: null },
  },

  computed: {
    activeRoutes() {
      return this.$router.options.routes.filter(r => {
        return !(this.newRecord && r.path !== "/")
      })
    },
  },

  methods: {
    navLabel: key => translate(`villa_editor.nav.${key}.label`),
  },
}
</script>
