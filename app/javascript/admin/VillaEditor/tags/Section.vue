<template>
  <fieldset>
    <legend v-text="section.category.label" />

    <!-- room configuration -->
    <div
        v-if="section.category.multiple_types"
        class="row"
    >
      <label class="control-label col-sm-2">Räume</label>
      <VillaRooms
          v-model="value.areas.$each.$iter[section.category.id]"
          :category="section.category"
          class="col-sm-10 col-lg-8"
          @add-area="value.$model.addArea(null, section.category.id)"
      />
    </div>

    <!-- ordinary tag selection -->
    <template v-else>
      <CountableTag
          v-for="(t, id) in taggingsByCountability.countable"
          :key="id"
          v-model="taggingsByCountability.countable[id]"
          :name="tagName(id)"
      />

      <div
          v-if="taggingsByCountability.uncountable.length"
          class="form-group"
      >
        <label class="control-label col-sm-2">Merkmale</label>
        <div class="col-sm-10 col-lg-8 tags">
          <div
              v-for="(t, id) in taggingsByCountability.uncountable"
              :key="id"
              class="checkbox"
          >
            <label @click.prevent="toggleTag(t)">
              <input
                  v-model="t.$model"
                  type="checkbox"
                  value="1"
                  class="hidden"
              >
              <i
                  class="fa fa-fw fa-lg"
                  :class="tagToggleClasses(t.$model)"
              />
              {{ tagName(id) }}
            </label>
          </div>
        </div>
      </div>
    </template>

    <!-- de/en description fields -->
    <div
        v-for="desc in section.descriptions"
        :key="desc.key"
        class="form-group"
    >
      <label
          class="control-label col-sm-2"
          v-text="desc.label"
      />

      <div
          v-for="loc in locales"
          :key="loc"
          class="col-sm-5 col-lg-4"
          :class="descFormGroupClass(desc, loc)"
      >
        <a
            v-if="desc.hasRichFormatting"
            href="#"
            class="btn btn-xxs btn-default pull-right"
            @click.prevent="$emit('editor', ['descriptions', desc.key, loc])"
        >
          <i class="fa fa-arrows-alt" />
          Vollbild mit Vorschau
        </a>
        <label
            :for="`villa_descriptions_${desc.key}_${loc}`"
            class="control-label"
        >
          <span
              class="fi"
              :class="`fi-${loc === 'en' ? 'us' : loc}`"
          />
          auf {{ loc === "de" ? "deutsch" : "englisch" }}
        </label>
        <textarea
            v-if="desc.hasRichFormatting"
            :id="`villa_descriptions_${desc.key}_${loc}`"
            v-model.trim="value.descriptions[desc.key][loc].$model"
            :placeholder="descPlaceholder(desc, loc)"
            class="form-control"
            :rows="5"
        />
        <input
            v-else
            :id="`villa_descriptions_${desc.key}_${loc}`"
            v-model.trim="value.descriptions[desc.key][loc].$model"
            :placeholder="descPlaceholder(desc, loc)"
            type="text"
            class="form-control"
        >
      </div>
    </div>
  </fieldset>
</template>

<script>
import { Tag } from "../models"
import CountableTag from "./CountableTag.vue"
import VillaRooms from "./VillaRooms.vue"

export default {
  components: {
    CountableTag,
    VillaRooms,
  },

  props: {
    value:   { type: Object, required: true }, // $v.villa from parent
    section: { type: Object, required: true },
  },

  data() {
    return {
      locales: ["de", "en"],
    }
  },

  computed: {
    taggingsByCountability() {
      const iter = this.value.taggings.$each.$iter[this.section.category.id],
            grouped = { countable: {}, uncountable: {} }
      if (!iter || !iter.$each.$iter) {
        return grouped
      }

      const props = {
        configurable: false,
        enumerable:   false,
        get() {
          return Object.keys(this).length
        },
      }
      Object.defineProperty(grouped.countable, "length", props)
      Object.defineProperty(grouped.uncountable, "length", props)

      return Object.entries(iter.$each.$iter).reduce((acc, cur) => {
        const id = Number(cur[0]),
              tag = Tag.byID(id)
        if (tag.countable) {
          acc.countable[id] = cur[1]
        } else {
          acc.uncountable[id] = cur[1]
        }
        return acc
      }, grouped)
    },
  },

  methods: {
    descFormGroupClass(desc, loc) {
      const f = this.value.descriptions[desc.key][loc]
      return {
        "has-error":   f.$error,
        "has-warning": !f.$error && f.$dirty,
      }
    },

    descPlaceholder(desc, loc) {
      return `${desc.label} auf ${loc === "de" ? "deutsch" : "englisch"}`
    },

    tagFormGroupClass(v) {
      return {
        "has-error":   v.$error,
        "has-warning": !v.$error && v.$dirty,
      }
    },

    tagName(id) {
      return Tag.byID(id).description
    },

    tagToggleClasses(value) {
      const selected = value > 0
      return {
        "fa-toggle-on":  selected,
        "fa-toggle-off": !selected,
        "text-muted":    !selected,
        "text-info":     selected,
      }
    },

    toggleTag(v) {
      v.$model = v.$model > 0 ? 0 : 1
      v.$touch()
    },
  },
}
</script>

<style scoped>
@media screen and (min-width: 483px) {
  .tags {
    display: grid;
    grid-template-columns: repeat(2, fit-content(50%));
    grid-gap: 0 10px;
  }
}
@media screen and (min-width: 768px) {
  .tags {
    grid-template-columns: repeat(3, fit-content(33%));
    grid-gap: 0 15px;
  }
}
@media screen and (min-width: 992px) {
  .tags {
    grid-template-columns: repeat(4, fit-content(25%));
    grid-gap: 5px 20px;
  }
}
.tags .checkbox {
  white-space: nowrap;
}
.tags .checkbox > label {
  padding-left: 0;
}
</style>
