<template>
  <form
      action="#"
      @submit.prevent
  >
    <fieldset>
      <legend>Boote zuordnen</legend>

      <div class="row">
        <label class="control-label col-sm-2">
          Einschließlichkeit
        </label>

        <div class="col-sm-10 col-lg-8">
          <div
              v-for="(label, opt) in inclusionOptions"
              :key="opt"
              class="radio"
          >
            <label class="control-label">
              <input
                  v-model="$v.villa.boat.inclusion.$model"
                  type="radio"
                  name="inclusion"
                  :value="opt"
              > {{ label }}
            </label>
          </div>
        </div>
      </div>

      <div
          v-if="$v.villa.$model.boat.inclusion === 'inclusive'"
          class="row"
      >
        <label class="control-label col-sm-2">
          Exklusives Boot
        </label>

        <div
            class="col-sm-10 col-lg-8"
            :class="{ 'has-error': $v.villa.boat.exclusive_id.$invalid }"
        >
          <div
              v-for="boat in exclusiveBoats"
              :key="boat.id"
              class="radio"
          >
            <label class="control-label">
              <input
                  v-model="$v.villa.boat.exclusive_id.$model"
                  type="radio"
                  name="exclusive_boat_id"
                  :value="boat.id"
              > {{ boat.name }}
            </label>
          </div>

          <span
              v-if="$v.villa.boat.exclusive_id.$invalid"
              class="help-block"
          >
            Es muss ein Boot ausgewählt werden.
          </span>
        </div>
      </div>

      <div
          v-if="$v.villa.$model.boat.inclusion === 'optional'"
          class="row"
      >
        <label class="control-label col-sm-2">
          Optionale Boote
        </label>

        <div class="col-sm-10 col-lg-8">
          <div
              v-for="boat in optionalBoats"
              :key="boat.id"
              class="checkbox"
          >
            <label class="control-label">
              <input
                  v-model="$v.villa.boat.optional_ids.$model"
                  type="checkbox"
                  name="optional_boat_ids"
                  :value="boat.id"
              > {{ boat.name }}
            </label>
          </div>
        </div>
      </div>
    </fieldset>

    <slot
        name="buttons"
        :payload-fn="buildPayload"
        :active="!wasClean"
    />
  </form>
</template>

<script>
import Utils from "../../intervillas-drp/utils"
import { Boat } from "./models"
import Common from "./common"
import { validationMixin } from "vuelidate"
import { required, requiredIf, inCollection } from "./validators"

const INCLUSIVITIES = Object.freeze({
  none:      "kein Boot möglich",
  inclusive: "eigenes Boot (im Mietpreis enthalten)",
  optional:  "Boot optional buchbar",
})

export default {
  mixins: [Common, validationMixin],

  validations() {
    return {
      villa: {
        boat: {
          inclusion: {
            required,
            inCollection: inCollection(Object.keys(INCLUSIVITIES)),
          },
          exclusive_id: {
            requiredIf: requiredIf(function(boat) {
              return boat.inclusion === "inclusive"
            }),
          },
          // TODO: is no selection a valid selection?
          optional_ids: {
            $each: {},
          },
        },
      },
    }
  },

  computed: {
    inclusionOptions() {
      return INCLUSIVITIES
    },

    exclusiveBoats() {
      return Boat.byAssignability("exclusive")
    },

    optionalBoats() {
      return Boat.byAssignability("optional")
    },
  },

  methods: {
    buildPayload() {
      const { boat } = Utils.dup(this.villa)
      return { boat }
    },

    isValid() {
      return !this.$v.villa.boat.$invalid
    },
  },
}
</script>
