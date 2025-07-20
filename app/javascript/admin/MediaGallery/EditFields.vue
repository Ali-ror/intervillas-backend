<template>
  <form @submit.prevent>
    <div class="mb-2">
      <label class="control-label">Dateiname</label>
      <div class="input-group">
        <input
            v-model.trim="changes.filename"
            class="form-control"
            :readonly="saving"
            placeholder="Dateiname"
            type="text"
        >
        <span class="input-group-addon">
          .{{ medium.extname }}
        </span>
      </div>
    </div>

    <div class="mb-2">
      <label class="control-label">
        <ToggleSwitch
            :active="changes.active"
            :disabled="saving"
            @click="toggleActive()"
        >
          aktiv?
        </ToggleSwitch>
      </label>
    </div>

    <div class="mb-2">
      <label class="control-label">Beschreibung</label>
      <div class="input-group">
        <span class="input-group-addon">
          <span class="fi fi-de" />
        </span>
        <input
            v-model.trim="changes.de_description"
            class="form-control"
            placeholder="Beschreibung (deutsch)"
            :readonly="saving"
            type="text"
        >
      </div>
      <div class="input-group">
        <span class="input-group-addon">
          <span class="fi fi-us" />
        </span>
        <input
            v-model.trim="changes.en_description"
            class="form-control"
            placeholder="Beschreibung (englisch)"
            :readonly="saving"
            type="text"
        >
      </div>
    </div>

    <div v-if="medium.type === 'image'" class="mb-2">
      <label class="control-label">Tags</label>
      <div class="input-group">
        <span class="input-group-addon">
          <i class="fa fa-tags" />
        </span>
        <UiSelect
            v-model="changes.image_tags"
            :options="imageTags"
            :reduce="o => o.id"
            label="text"
            multiple
        />
      </div>
    </div>

    <div class="mt-3 mb-2">
      <button
          class="btn btn-sm"
          :class="dirty ? 'btn-primary' : 'btn-default'"
          :disabled="saving"
          type="button"
          @click.prevent="save"
      >
        <i class="fa fa-floppy-o" />
        speichern
      </button>

      <button
          v-if="medium.type === 'upload'"
          class="btn btn-sm btn-warning"
          type="button"
          @click.prevent="destroy"
      >
        <i class="fa fa-times" />
        Hochladen abbrechen
      </button>

      <button
          v-else
          class="btn btn-sm btn-warning ml-1"
          :disabled="saving"
          type="button"
          @click.prevent="destroy"
      >
        <i class="fa fa-trash-o" />
        löschen
      </button>

      <p
          v-if="message"
          class="form-control-static"
          :class="message.shade"
      >
        <i
            class="fa"
            :class="message.icon"
        />
        {{ message.text }}
      </p>
    </div>

    <p class="small text-muted">
      Karoussell-Code:
      <code>%carousel({{ medium.id }})%</code>
    </p>
  </form>
</template>

<script>
import ToggleSwitch from "../ToggleSwitch.vue"
import Utils from "../../intervillas-drp/utils"
import UiSelect from "../../components/UiSelect.vue"

export default {
  components: {
    ToggleSwitch,
    UiSelect,
  },

  props: {
    medium:    { type: Object, required: true },
    imageTags: { type: Array, default: null },
  },

  data() {
    return {
      saving:  this.medium.type === "upload",
      saved:   false,
      changes: {
        active:         this.medium.active,
        filename:       this.medium.filename,
        de_description: this.medium.de_description,
        en_description: this.medium.en_description,
        image_tags:     [...(this.medium.image_tags || [])],
      },
    }
  },

  computed: {
    dirty() {
      return this.changes.active !== this.medium.active
        || this.changes.filename !== this.medium.filename
        || this.changes.de_description !== this.medium.de_description
        || this.changes.en_description !== this.medium.en_description
        || !Utils.equalArrays(this.changes.image_tags, this.medium.image_tags, true)
    },

    message() {
      if (this.dirty) {
        return {
          shade: "text-muted",
          icon:  "fa-exclamation-triangle",
          text:  "ungespeicherte Änderungen",
        }
      }
      if (this.saving) {
        return {
          shade: "text-warning",
          icon:  ["fa-spinner", "fa-spin"],
          text:  "Speichere\u2026",
        }
      }
      if (this.saved) {
        return {
          shade: "text-success",
          icon:  "fa-check",
          text:  "Gespeichert!",
        }
      }
      return null
    },
  },

  watch: {
    "medium.id"() {
      this.reset()
    },
    "medium.active"() {
      this.reset()
    },
    dirty(becameDirty) {
      if (becameDirty) {
        this.saved = false
      }
    },
  },

  methods: {
    save() {
      this.saving = true

      const payload = {
        active:         this.changes.active,
        de_description: this.changes.de_description,
        en_description: this.changes.en_description,
      }

      if (this.medium.type === "image") {
        payload.image_tags = this.changes.image_tags
      }

      // silently discard empty filenames
      const fn = this.changes.filename
      if (fn.length > 0 && !/^\.+$/.test(fn)) {
        payload["filename"] = `${fn}.${this.medium.extname}`
      }

      Utils.putJSON(this.medium.url, { medium: payload }).then(data => {
        this.saving = false
        this.saved = true
        this.$emit("updated", data)
      })
    },

    destroy() {
      if (this.medium.type === "upload") {
        this.$emit("destroyed")
        return
      }
      if (!confirm("Dies kann nicht rückgängig gemacht werden. Fortfahren?")) {
        return
      }

      this.saving = true
      Utils.deleteJSON(this.medium.url, null).then(() => {
        this.$emit("destroyed")
      })
    },

    toggleActive() {
      this.changes.active = !this.changes.active
    },

    reset() {
      this.saving = false
      this.saved = false
      this.changes = {
        active:         this.medium.active,
        filename:       this.medium.filename,
        de_description: this.medium.de_description,
        en_description: this.medium.en_description,
        image_tags:     [...(this.medium.image_tags || [])],
      }
    },
  },
}
</script>

<style scoped>
  .input-group + .input-group {
    margin-top: 6px
  }
</style>
