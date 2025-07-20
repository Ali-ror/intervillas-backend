<template>
  <div>
    <table class="table table-condensed table-hover">
      <thead>
        <tr>
          <th>#</th>
          <th>Typ</th>
          <th v-if="category.name === 'bedrooms'">
            Anzahl Schlaf&shy;möglich&shy;keiten
          </th>
          <th
              v-for="tag in tags"
              :key="tag.id"
              class="text-center"
          >
            <TagDescription :tag="tag"/>
          </th>
          <th />
        </tr>
      </thead>

      <tbody>
        <tr
            v-for="(area, i) in value.$each.$iter"
            :key="i"
            :class="{
              success: area.$model.newRecord,
              warning: !area.$model.newRecord && area.$anyDirty,
              danger: area.$model._destroy,
            }"
        >
          <td v-text="+i+1" />
          <td :class="{ 'has-warning': area.subtype.$dirty }">
            <label
                :for="`villa_${category.name}_${i}_subtype`"
                class="hidden"
            >{{ name }} #{{ +i+1 }}: Typ</label>
            <select
                :id="`villa_${category.name}_${i}_subtype`"
                v-model="area.subtype.$model"
                class="form-control input-sm"
            >
              <option
                  v-for="t in types"
                  :key="t"
                  :value="t"
                  :disabled="area.$model._destroy"
              >
                {{ t | translate({ scope: "category_multiple_types" }) }}
              </option>
            </select>
          </td>
          <td
              v-if="category.name === 'bedrooms'"
              :class="{ 'has-warning': area.beds_count.$dirty }"
          >
            <label
                :for="`villa_${category.name}_${i}_beds_count`"
                class="hidden"
            >{{ name }} #{{ +i+1 }}: Anzahl Schlafmöglichkeiten</label>
            <input
                :id="`villa_${category.name}_${i}_beds_count`"
                v-model.number="area.beds_count.$model"
                type="number"
                class="form-control input-sm beds-count"
                :disabled="area.$model._destroy"
                min="0"
                step="1"
            >
          </td>
          <td
              v-for="tag in tags"
              :key="tag.id"
              class="text-center"
              :class="{ 'has-warning': area.taggings.$each.$iter[tag.id].$dirty }"
          >
            <label
                v-if="tag.countable"
                :for="`villa_${category.name}_${i}_tag_${tag.id}`"
                class="hidden"
            >{{ name }} #{{ +i+1 }}: {{ tag.description }}</label>
            <input
                v-if="tag.countable"
                :id="`villa_${category.name}_${i}_tag_${tag.id}`"
                v-model.number="area.taggings.$each.$iter[tag.id].$model"
                :disabled="area.$model._destroy"
                type="number"
                min="0"
                class="form-control input-sm"
            >
            <div
                v-else
                class="checkbox"
                @click.prevent="toggleTag(area, tag)"
            >
              <label>
                <span class="hidden">
                  {{ name }} #{{ +i+1 }}: {{ tag.description }}
                </span>
                <input
                    v-model="area.taggings.$each.$iter[tag.id].$model"
                    type="checkbox"
                    class="hidden"
                    value="1"
                >
                <i
                    class="fa fa-fw fa-lg"
                    :class="tagToggleClasses(area, tag)"
                />
              </label>
            </div>
          </td>
          <td class="text-right">
            <button
                v-if="area.$model._destroy"
                class="btn btn-xxs btn-default"
                type="button"
                @click="area._destroy.$model = false"
            >
              <i class="fa fa-undo" /> behalten
            </button>
            <button
                v-else
                class="btn btn-xxs btn-warning"
                type="button"
                @click="area._destroy.$model = true"
            >
              <i class="fa fa-trash" /> löschen
            </button>
          </td>
        </tr>
      </tbody>

      <tfoot>
        <tr>
          <td :colspan="tags.length + 3 + (category.name === 'bedrooms' ? 1 : 0)">
            <button
                class="btn btn-xxs btn-default"
                type="button"
                @click.prevent="$emit('add-area')"
            >
              <i class="fa fa-plus" />
              {{ name }} hinzufügen
            </button>
          </td>
        </tr>
      </tfoot>
    </table>
  </div>
</template>

<script>
import { Tag, Category } from "../models"
import TagDescription from "./TagDescription.vue"

export default {
  components: {
    TagDescription,
  },

  props: {
    value:    { type: Object, required: true },
    category: { type: Category, required: true },
  },

  computed: {
    types() {
      return this.category.multiple_types
    },

    name() {
      return this.category.label
    },

    tags() {
      return this.category.tags
    },
  },

  methods: {
    tagName(id) {
      return Tag.byID(id).description
    },

    toggleTag(area, tag) {
      const tagging = area.taggings.$each.$iter[tag.id]
      tagging.$model = tagging.$model > 0 ? 0 : 1
    },

    tagToggleClasses(area, tag) {
      const v = area.taggings.$each.$iter[tag.id],
            selected = v.$model > 0,
            dirty = v.$dirty

      return {
        "fa-toggle-on":  selected,
        "fa-toggle-off": !selected,
        "text-muted":    !selected && !dirty,
        "text-info":     selected && !dirty,
        "text-warning":  dirty,
      }
    },
  },
}
</script>

<style scoped>
.checkbox > label {
  padding: 6px 12px;
  margin: -6px 0;
}

td > input,
td > select {
  margin: -4px -3px;
}

td > select {
  width: 10em;
}
</style>
