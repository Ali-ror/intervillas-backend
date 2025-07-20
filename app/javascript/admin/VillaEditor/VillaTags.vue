<template>
  <MarkdownEditor
      v-if="editor"
      v-model="editor.$model"
      :title="editorTitle"
      @close="hideEditor"
  />

  <form
      v-else
      action="#"
      class="form-horizontal"
      @submit.prevent
  >
    <TagSection
        v-for="sec of villa.sections"
        :key="sec.category.name"
        v-model="$v.villa"
        :section="sec"
        @editor="showEditor"
    />

    <slot
        v-if="!editor"
        name="buttons"
        :payload-fn="buildPayload"
        :active="!wasClean"
    />
  </form>
</template>

<script>
import Common from "./common"
import MarkdownEditor from "../MarkdownEditor.vue"
import TagSection from "./tags/Section.vue"
import { Category } from "./models"
import { validationMixin } from "vuelidate"
import { minValue, required } from "./validators"

export default {
  components: {
    MarkdownEditor,
    TagSection,
  },

  mixins: [Common, validationMixin],

  validations() {
    return {
      villa: {
        descriptions: {
          header:        { de: {}, en: {} },
          teaser:        { de: {}, en: {} },
          description:   { de: {}, en: {} },
          entertainment: { de: {}, en: {} },
          outdoor:       { de: {}, en: {} },
          theme:         { de: {}, en: {} },
          gym:           { de: {}, en: {} },
          accessoires:   { de: {}, en: {} },
          lavatory:      { de: {}, en: {} },
          livingroom:    { de: {}, en: {} },
          kitchen:       { de: {}, en: {} },
          bathrooms:     { de: {}, en: {} },
          bedrooms:      { de: {}, en: {} },
        },
        taggings: { // category_id → tag_id → amount
          $each: {
            $each: { minValue: minValue(0) },
          },
        },
        areas: { // category_id → list of areas
          $each: {
            $each: {
              subtype:  { required },
              taggings: {
                $each: { minValue: minValue(0) },
              },
              beds_count: {},
              _destroy:   {},
            },
          },
        },
      },
    }
  },

  data() {
    return {
      editor:      false,
      editorTitle: null,
    }
  },

  computed: {
    categoryByName() {
      return Object.keys(this.villa.taggings).reduce((acc, id) => {
        const cat = Category.byID(Number(id))
        acc[cat.name] = cat
        return acc
      }, {})
    },
  },

  methods: {
    showEditor([section, description, locale]) {
      const desc = this.$v.villa[section][description]

      this.editor = desc[locale]
      this.editorTitle = [
        Category.byID(desc.$model.category_id).label,
        desc.$model.label,
        locale.toUpperCase(),
      ].join(" · ")
    },

    hideEditor() {
      this.editor = false
      this.editorTitle = null
    },
  },
}
</script>
