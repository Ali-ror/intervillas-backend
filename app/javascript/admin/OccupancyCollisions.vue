<template>
  <form @submit.prevent="onSubmit">
    <UiCard
        variant="danger"
        heading="Kollisionen vorhanden"
        no-body
    >
      <div class="panel-body">
        <p>Kalender kann nicht angezeigt werden.</p>
        <p>Bitte zuerst alle Doppelbelegungen lösen!</p>
      </div>

      <AsyncLoader
          v-if="type === 'Villa'"
          :url="collisionsUrl"
          @data="onData"
      >
        <table v-if="collisions.length" class="table table-striped table-condensed">
          <thead>
            <tr>
              <th class="w-1">
                <input
                    type="checkbox"
                    v-model="selectAll"
                    :value="true"
                    :disabled="saving || collisions.length === 0"
                    :indeterminate.prop="selected.length > 0 && selected.length < collisions.length"
                >
              </th>
              <th>Blockierung</th>
              <th>Beginn</th>
              <th>Ende</th>
              <th>Notiz</th>
              <th>kollidiert mit</th>
              <th>Anreise</th>
              <th>Abreise</th>
            </tr>
          </thead>

          <tbody>
            <tr v-for="row in flattenedCollisions" :key="row.key">
              <template v-if="'collision' in row">
                <td>
                  <input
                      type="checkbox"
                      v-model="selected"
                      :value="row.collision.id"
                      :disabled="saving"
                  >
                </td>
                <td>
                  <a :href="`/admin/blockings/${row.collision.id}/edit`">
                    {{ row.collision.number }}
                  </a>
                </td>
                <td>{{ formatDate(row.collision.start_date) }}</td>
                <td>{{ formatDate(row.collision.end_date) }}</td>
                <td>{{ row.collision.comment }}</td>
              </template>
              <td v-else colspan="5" />

              <td>
                <a :href="row.clash.url">
                  {{ row.clash.number }}
                </a>
              </td>
              <td>{{ formatDate(row.clash.start_date) }}</td>
              <td>{{ formatDate(row.clash.end_date) }}</td>
            </tr>
          </tbody>
        </table>

        <div v-else class="panel-body">
          <div class="alert alert-info">
            Alle Kollisionen gelöst.
            <a class="alert-link" :href="currentUrl">Seite neu laden</a>.
          </div>
        </div>
      </AsyncLoader>

      <template #footer>
        <UiButton
            v-if="type === 'Villa'"
            type="submit"
            class="mr-2"
            :disabled="saving || (selected.length === 0 && collisions.length === 0)"
            variant="warning"
        >
          <i class="fa fa-spinner fa-pulse" v-if="saving" />
          Ausgewählte ignorieren
        </UiButton>

        <UiButton :url="indexUrl" label="Zurück zum Belegungskalender" />
      </template>
    </UiCard>
  </form>
</template>

<script>
import UiButton from "../components/UiButton.vue"
import UiCard from "../components/UiCard.vue"
import AsyncLoader from "./AsyncLoader.vue"
import { formatDate } from "../lib/DateFormatter"
import Utils from "../intervillas-drp/utils"

export default {
  components: {
    UiCard,
    UiButton,
    AsyncLoader,
  },

  props: {
    type: { type: String, required: true }, // rentable.class ("Villa" | "Boat")
    id:   { type: String, required: true }, // rentable#to_param (ID + slug)
    year: { type: Number, required: true },
  },

  data() {
    return {
      collisions: [],
      selected:   [],
      saving:     false,
    }
  },

  computed: {
    pathFragment() {
      switch (this.type) {
      case "Villa":
        return "villas"
      case "Boat":
        return "boats"
      default:
        throw new Error(`unexpected type: ${this.type}`)
      }
    },

    currentUrl() {
      return window.location.toString()
    },

    indexUrl() {
      return ["/admin", this.pathFragment, this.id, "occupancies"].join("/")
    },

    collisionsUrl() {
      return ["/api/admin/occupancies", this.pathFragment, this.id, "collisions", this.year].join("/")
    },

    flattenedCollisions() {
      return this.collisions.flatMap(collision => {
        return collision.clashes.map((clash, i) => ({
          key: `${collision.id}-${i}`,
          ...(i === 0 ? { collision } : {}),
          clash,
        }))
      })
    },

    selectAll: {
      get() {
        const have = this.collisions.length,
              selected = this.selected.length
        return have > 0 && selected === have
      },
      set(val) {
        this.selected = val
          ? this.collisions.map(c => c.id)
          : []
      },
    },
  },

  methods: {
    formatDate,

    onData(data) {
      this.collisions = data
    },

    async onSubmit() {
      this.saving = true

      try {
        const data = await Utils.patchJSON(this.collisionsUrl, {
          blocking: { ids: this.selected },
        })

        if (data.length === 0) {
          window.location.reload()
        } else {
          this.collisions = data
          this.selected = []
        }
      } finally {
        this.saving = false
      }
    },
  },
}
</script>
