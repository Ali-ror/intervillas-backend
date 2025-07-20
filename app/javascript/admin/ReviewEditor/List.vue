<template>
  <div>
    <div class="form-inline">
      <div class="input-group">
        <span class="input-group-addon">
          Filter
        </span>
        <select
            v-model="currentFilter"
            class="form-control"
        >
          <option
              v-for="(f, name) in filters"
              :key="name"
              :value="name"
              v-text="f.text"
          />
        </select>
        <span class="input-group-addon">
          <abbr title="gefilterte Bewertungen">{{ filtered.length }}</abbr>
          von
          <abbr title="Bewertungen insgesamt">{{ reviews.length }}</abbr>
        </span>
      </div>

      <div
          v-if="rating && rating > 0"
          class="input-group"
      >
        <span class="input-group-addon">
          <abbr title="Durchschnitt der angezeigten Bewertungen">
            Durchschnitt
          </abbr>
        </span>
        <div class="form-control">
          <div class="rating">
            <i
                v-for="(shape, i) in stars(Math.round(rating))"
                :key="i"
                class="star"
                :class="shape"
            />
          </div>
        </div>
        <span class="input-group-addon">
          {{ rating.toFixed(1) }}
        </span>
      </div>
    </div>

    <table class="table table-striped js-sticky-header">
      <thead>
        <tr>
          <th style="width:150px">
            Buchung/Zeitraum
          </th>
          <th style="width:90px">
            öffentlich?
          </th>
          <th>
            Bewertung
          </th>
          <th style="width:5em" />
        </tr>
      </thead>

      <tbody>
        <tr v-for="r in filtered" :key="r.id">
          <td :data-id="r.id">
            <a :href="r.booking.url" v-text="r.booking.number" />
            <div class="small">
              {{ formatDate(r.booking.start_date) }} bis
              {{ formatDate(r.booking.end_date) }}
            </div>
          </td>

          <td>
            <ToggleSwitch
                :active="!!r.published_at"
                :disabled="r.saving"
                @click="$emit('toggle-publish', r)"
            >
              <span v-if="r.published_at" class="text-success">ja</span>
              <span v-else class="text-muted">nein</span>
            </ToggleSwitch>
          </td>

          <td>
            <ul class="list-inline">
              <li v-if="r.rating" :title="`${r.rating} von 5 Sternen`">
                <div class="rating">
                  <i
                      v-for="(shape, i) in stars(r.rating)"
                      :key="i"
                      class="star"
                      :class="shape"
                  />
                </div>
              </li>
              <li>
                <span class="text-muted">Name</span>
                {{ r.name || "fehlt" }}
              </li>
              <li>
                <span class="text-muted">Ort</span>
                {{ r.city || "fehlt" }}
              </li>
            </ul>

            <!-- eslint-disable vue/no-v-html -->
            <div
                v-if="r.preview"
                class="preview"
                v-html="r.preview"
            />
            <!-- eslint-enable vue/no-v-html -->
            <div v-else>
              <em class="text-muted">kein Text</em>
            </div>
          </td>

          <td class="text-right">
            <a
                href="#"
                title="bearbeiten"
                @click.prevent="$emit('edit', r)"
            >
              <i class="fa fa-2x fa-pencil" />
            </a>

            <a
                href="#"
                title="löschen"
                @click.prevent="$emit('destroy', r)"
            >
              <i class="fa fa-2x fa-trash text-danger" />
            </a>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import ToggleSwitch from "../ToggleSwitch.vue"
import { formatDate } from "../../lib/DateFormatter"

const filter = (text, predicate) => {
  const f = reviews => reviews.filter(predicate)
  f.text = text
  return f
}

const FILTERS = Object.freeze({
  all:         filter("alle", () => true),
  published:   filter("veröffentlicht", r => r.published_at),
  publishable: filter("noch nicht veröffentlicht", r => r.isPublishable),
  complete:    filter("vollständig", r => r.isComplete),
  incomplete:  filter("unvollständig", r => r.isIncomplete),
  nostars:     filter("unvollständig (Text, aber keine Sterne)", r => r.isNoStars),
})

export default {
  components: {
    ToggleSwitch,
  },

  props: {
    reviews: { type: Array, default: () => ([]) },
  },

  data() {
    return {
      filters:       FILTERS,
      currentFilter: "all",
    }
  },

  computed: {
    filtered() {
      return FILTERS[this.currentFilter](this.reviews)
    },

    rating() {
      const { sum, count } = this.filtered.reduce((total, r) => {
        if (r.hasRating) {
          total.sum += r.rating
          total.count++
        }
        return total
      }, { sum: 0, count: 0 })

      return count > 0 ? sum / count : 0
    },
  },

  methods: {
    formatDate,

    stars(rating) {
      // TODO: implement half-star for fractional ratings
      const stars = [...new Array(5)],
            pivot = 5 - rating
      stars[pivot] = "active"
      return stars
    },
  },
}
</script>

<style scoped>
.preview {
  border-left: 3px solid #75c5cf;
  padding-left: 12px;
}
</style>
