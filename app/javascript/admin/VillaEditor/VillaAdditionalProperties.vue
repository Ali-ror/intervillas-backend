<template>
  <form action="#" @submit.prevent>
    <p>
      <i class="fa fa-info-circle text-info" />
      These properties are only used for further distribution to various channels via MyBookingPal.

      <a v-if="villa.booking_pal_product" :href="`/admin/my_booking_pal/products/${villa.booking_pal_product.id}`">
        Show MBP product details.
      </a>
      <a v-else :href="`/admin/my_booking_pal/products/new?villa_id=${villa.id}`">
        Setup an MBP product.
      </a>
    </p>

    <div class="d-flex flex-row flex-wrap justify-content-between align-items-start gap-3 mt-3">
      <fieldset key="misc">
        <legend>Miscellaneous</legend>

        <div class="form-group">
          <label
              class="control-label"
              for="villa_additional_properties_property_type"
          >Property type</label>
          <select
              id="villa_additional_properties_property_type"
              v-model="$v.villa.additional_properties.property_type.$model"
              class="form-control"
          >
            <option
                v-for="[id, text] of propertyTypes"
                :key="id"
                :value="id"
                v-text="text"
            />
          </select>
        </div>

        <div class="form-group">
          <label
              for="villa_additional_properties_children_allowed"
              class="control-label"
          >Children allowed?</label>
          <select
              id="villa_additional_properties_children_allowed"
              v-model="$v.villa.additional_properties.children_allowed.$model"
              class="form-control"
          >
            <option :value="true">
              yes
            </option>
            <option :value="false">
              no
            </option>
          </select>
        </div>

        <div class="form-group">
          <label
              for="villa_additional_properties_smoking_allowed"
              class="control-label"
          >Smoking allowed?</label>
          <select
              id="villa_additional_properties_smoking_allowed"
              v-model="$v.villa.additional_properties.smoking_allowed.$model"
              class="form-control"
          >
            <option :value="true">
              yes
            </option>
            <option :value="false">
              no
            </option>
          </select>
        </div>
      </fieldset>

      <fieldset key="pet-policy">
        <legend>Pet Policy</legend>

        <div class="form-group">
          <label
              for="villa_additional_properties_pet_policy_allowed"
              class="control-label"
          >Pets allowed?</label>
          <select
              id="villa_additional_properties_pet_policy_allowed"
              v-model="$v.villa.additional_properties.pet_policy.allowed.$model"
              class="form-control"
          >
            <option :value="true">
              yes
            </option>
            <option :value="false">
              no
            </option>
            <option value="request">
              on request
            </option>
          </select>
        </div>

        <div v-if="villa.additional_properties.pet_policy.allowed" class="form-group">
          <label
              for="villa_additional_properties_pet_policy_fee"
              class="control-label"
          >Fees</label>
          <div class="input-group">
            <input
                id="villa_additional_properties_pet_policy_fee"
                v-model.number="$v.villa.additional_properties.pet_policy.fee.$model"
                type="number"
                class="form-control"
                min="0"
                step="0.01"
            >
            <span class="input-group-addon">
              <CurrencyIcon currency="USD"/>
            </span>
          </div>
          <span class="help-block">
            Leave empty (or set to 0) to waive fees.
          </span>
        </div>
      </fieldset>

      <fieldset key="internet-policy">
        <legend>Internet Policy</legend>

        <div class="form-group">
          <label
              for="villa_additional_properties_internet_policy_available"
              class="control-label"
          >Available?</label>
          <select
              id="villa_additional_properties_internet_policy_available"
              v-model="$v.villa.additional_properties.internet_policy.available.$model"
              class="form-control"
          >
            <option :value="true">
              yes
            </option>
            <option :value="false">
              no
            </option>
          </select>
        </div>

        <template v-if="villa.additional_properties.internet_policy.available">
          <div class="form-group">
            <label
                for="villa_additional_properties_internet_policy_type"
                class="control-label"
            >Type</label>
            <select
                id="villa_additional_properties_internet_policy_type"
                v-model="$v.villa.additional_properties.internet_policy.type.$model"
                class="form-control"
            >
              <option value="wireless">
                wireless, Wifi
              </option>
              <option value="wired">
                wired, Ethernet
              </option>
            </select>
          </div>

          <div class="form-group">
            <label
                for="villa_additional_properties_internet_policy_locations"
                class="control-label"
            >Locations</label>
            <select
                id="villa_additional_properties_internet_policy_locations"
                v-model="$v.villa.additional_properties.internet_policy.locations.$model"
                class="form-control"
            >
              <option value="all">
                in all areas
              </option>
              <option value="office">
                only in office rooms
              </option>
              <option value="some">
                only in some rooms
              </option>
            </select>
          </div>

          <div class="form-group">
            <label for="villa_additional_properties_internet_policy_fee">Fees</label>
            <div class="input-group">
              <input
                  id="villa_additional_properties_internet_policy_fee"
                  v-model.number="$v.villa.additional_properties.internet_policy.fee.$model"
                  type="number"
                  class="form-control"
                  min="0"
                  step="0.01"
              >
              <span class="input-group-addon">
                <CurrencyIcon currency="USD"/>
              </span>
            </div>
            <span class="help-block">
              Leave empty (or set to 0) if internet access is provided free of charge.
            </span>
          </div>
        </template>
      </fieldset>
    </div>

    <div class="d-flex flex-row flex-wrap justify-content-between align-items-start gap-3 mt-3">
      <fieldset key="los">
        <legend>Booking Stay</legend>

        <div class="d-flex align-items-start gap-2">
          <div class="form-group">
            <label class="control-label" for="villa_additional_properties_los_min_stay">Min. Length</label>
            <div class="input-group">
              <input
                  id="villa_additional_properties_los_min_stay"
                  v-model.number="$v.villa.additional_properties.los.min_stay.$model"
                  type="number"
                  min="1"
                  :max="$v.villa.additional_properties.los.max_stay.$model"
                  class="form-control"
              >
              <span class="input-group-addon">
                day{{ $v.villa.additional_properties.los.min_stay.$model === 1 ? "" : "s" }}
              </span>
            </div>
          </div>

          <div class="form-group">
            <label class="control-label" for="villa_additional_properties_los_max_stay">Max. Length</label>
            <div class="input-group">
              <input
                  id="villa_additional_properties_los_max_stay"
                  v-model.number="$v.villa.additional_properties.los.max_stay.$model"
                  type="number"
                  max="46"
                  :min="$v.villa.additional_properties.los.min_stay.$model"
                  class="form-control"
              >
              <span class="input-group-addon">
                day{{ $v.villa.additional_properties.los.max_stay.$model === 1 ? "" : "s" }}
              </span>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label class="control-label" for="villa_additional_properties_los_advance_months">
            Latest Arrival
          </label>
          <div class="input-group">
            <input
                id="villa_additional_properties_los_advance_months"
                v-model.number="$v.villa.additional_properties.los.advance_months.$model"
                type="number"
                min="1"
                max="24"
                class="form-control"
            >
            <span class="input-group-addon">
              month{{ $v.villa.additional_properties.los.advance_months.$model === 1 ? "" : "s" }}
            </span>
          </div>
          <div class="help-block">
            Availabilities/Length-of-Stay prices will be precomputed based on this information.
            The latest arrival date defines how much data must be processed.
          </div>
        </div>

        <div class="form-group">
          <label class="control-label" for="villa_additional_properties_los_surcharge">
            Surcharge
          </label>
          <div class="input-group">
            <input
                id="villa_additional_properties_los_surcharge"
                v-model.number="$v.villa.additional_properties.los.surcharge.$model"
                type="number"
                min="0"
                step="1"
                class="form-control"
            >
            <span class="input-group-addon">
              %
            </span>
          </div>
          <div class="help-block">
            Percentage value by which the gross rental price will be increased
            (to counteract MBP and channel commission).
          </div>
        </div>
      </fieldset>

      <fieldset key="parking-policy">
        <legend>Parking Policy</legend>

        <div class="form-group">
          <label
              for="villa_additional_properties_parking_policy_available"
              class="control-label"
          >Available?</label>
          <select
              id="villa_additional_properties_parking_policy_available"
              v-model="$v.villa.additional_properties.parking_policy.available.$model"
              class="form-control"
          >
            <option :value="true">
              yes
            </option>
            <option :value="false">
              no
            </option>
          </select>
        </div>

        <template v-if="villa.additional_properties.parking_policy.available">
          <div class="form-group">
            <label
                for="villa_additional_properties_parking_policy_type"
                class="control-label"
            >Type</label>
            <select
                id="villa_additional_properties_parking_policy_type"
                v-model="$v.villa.additional_properties.parking_policy.type.$model"
                class="form-control"
            >
              <option value="onsite">
                on-site parking
              </option>
              <option value="nearby">
                parking nearby
              </option>
            </select>
          </div>

          <div v-if="villa.additional_properties.parking_policy.type === 'nearby'" class="form-group">
            <label
                for="villa_additional_properties_parking_policy_private"
                class="control-label"
            >Private Parking?</label>
            <select
                id="villa_additional_properties_parking_policy_private"
                v-model="$v.villa.additional_properties.parking_policy.private.$model"
                class="form-control"
            >
              <option :value="true">
                yes
              </option>
              <option :value="false">
                no
              </option>
            </select>
          </div>

          <div class="form-group">
            <label
                for="villa_additional_properties_parking_policy_fee"
                class="control-label"
            >Fees</label>
            <div class="input-group">
              <input
                  id="villa_additional_properties_parking_policy_fee"
                  v-model.number="$v.villa.additional_properties.parking_policy.fee.$model"
                  type="number"
                  class="form-control"
                  min="0"
                  step="0.01"
              >
              <span class="input-group-addon">
                <CurrencyIcon currency="USD"/>
              </span>
              <select
                  id-model="$v.villa.additional_properties.parking_policy.fee_unit.$model"
                  name="villa_additional_properties_parking_policy_fee_unit"
                  class="form-control"
              >
                <option value="hour">
                  per hour
                </option>
                <option value="day">
                  per day
                </option>
                <option value="week">
                  per week
                </option>
                <option value="stay">
                  per stay
                </option>
              </select>
            </div>
            <span class="help-block">
              Leave empty (or set to 0) if parking is free.
            </span>
          </div>

          <div class="form-group">
            <label
                for="villa_additional_properties_parking_policy_reservation"
                class="control-label"
            >Reservation</label>
            <select
                id="villa_additional_properties_parking_policy_reservation"
                v-model="$v.villa.additional_properties.parking_policy.reservation.$model"
                class="form-control"
            >
              <option value="not_needed">
                not needed
              </option>
              <option value="not_possible">
                not possible
              </option>
              <option value="required">
                required
              </option>
            </select>
          </div>
        </template>
      </fieldset>

      <fieldset key="key-collection">
        <legend>Key Collection</legend>

        <div class="form-group">
          <label class="control-label" for="villa_additional_properties_key_collection_method">Check-In Method</label>
          <select
              id="villa_additional_properties_key_collection_method"
              v-model="$v.villa.additional_properties.key_collection.method.$model"
              class="form-control"
          >
            <option
                v-for="[id, text] of keyCollectionMethods"
                :key="id"
                :value="id"
                v-text="text"
            />
          </select>
        </div>

        <div class="form-group">
          <label class="control-label" for="villa_additional_properties_key_collection_how">How should keys be collected?</label>
          <textarea
              id="villa_additional_properties_key_collection_how"
              v-model="$v.villa.additional_properties.key_collection.how.$model"
              class="form-control"
              rows="4"
          />
        </div>

        <div class="form-group">
          <label class="control-label" for="villa_additional_properties_key_collection_when">When should keys be collected?</label>
          <textarea
              id="villa_additional_properties_key_collection_when"
              v-model="$v.villa.additional_properties.key_collection.when.$model"
              class="form-control"
              rows="4"
          />
        </div>
      </fieldset>
    </div>

    <div class="d-flex flex-row flex-wrap justify-content-between align-items-start gap-3 mt-3">
      <AmenityFieldset
          key="resort-amenities"
          class="half"
          label="Resort Amenities"
          v-model="$v.villa.additional_properties.extra_tags.$model"
          :options="resortAmenities"
          :preselected="villa.amenity_ids"
          kind="resort"
      />

      <AmenityFieldset
          key="room-amenities"
          class="half"
          label="Room Amenities"
          v-model="$v.villa.additional_properties.extra_tags.$model"
          :options="roomAmenities"
          :preselected="villa.amenity_ids"
          kind="room"
      />
    </div>

    <slot
        name="buttons"
        :payload-fn="buildPayload"
        :active="!wasClean"
    />
  </form>
</template>

<script>
import Common from "./common"
import { validationMixin } from "vuelidate"
import { between, numeric, minValue } from "vuelidate/lib/validators"
import AmenityFieldset from "./AmenityFieldset.vue"
import CurrencyIcon from "./CurrencyIcon.vue"

import { RESORT_AMENITIES, ROOM_AMENITIES } from "../MyBookingPal/amenities"

// sub-selection of Property Types Enum,
// https://channelconnector.com/opendoc#/rest/models/enumerations/property-types-enum
const PROPERTY_TYPES = new Map([
  ["PCT111", "bungalow"],
  ["PCT5", "cabin or bungalow"],
  ["PCT8", "condominium"],
  ["PCT114", "cottage"],
  ["PCT16", "guest house limited service"],
  ["PCT22", "lodge"],
  ["PCT52", "manor"],
  ["PCT40", "pension"],
  ["PCT128", "penthouse"],
  ["PCT32", "self catering accommodation"],
  ["PCT110", "studio"],
  ["PCT101", "townhome"],
  ["PCT34", "vacation home"],
  ["PCT35", "villa"],
])

// https://channelconnector.com/opendoc#/rest/models/enumerations/key-collection-checkinmethod
const KEY_COLLECTION_METHODS = new Map([
  ["doorman", "doorman"],
  ["front_desk", "front desk"],
  ["in_person_meet", "in-person meeting"],
  ["keypad", "key pad"],
  ["lock_box", "safe or lock box"],
  ["secret_spot", "secret spot"],
  ["smart_lock", "smart lock"],
  ["instruction_contact_us", "contact us for instructions"],
  ["other", "other..."],
])

export default {
  components: {
    AmenityFieldset,
    CurrencyIcon,
  },

  mixins: [Common, validationMixin],

  validations() {
    const minStay = this.villa.additional_properties?.min_stay ?? 1,
          maxStay = this.villa.additional_properties?.max_stay ?? 46

    return {
      villa: {
        additional_properties: {
          property_type:    {},
          children_allowed: {},
          smoking_allowed:  {},

          pet_policy: {
            allowed: {},
            fee:     {},
          },
          internet_policy: {
            available: {},
            type:      {},
            locations: {},
            fee:       {},
          },
          parking_policy: {
            available:   {},
            type:        {},
            private:     {},
            fee:         {},
            fee_unit:    {},
            reservation: {},
          },
          key_collection: {
            method: {},
            how:    {},
            when:   {},
          },
          los: {
            min_stay:       { between: between(1, maxStay) },
            max_stay:       { between: between(minStay + 1, 46) },
            advance_months: { between: between(1, 24) },
            surcharge:      { numeric, minValue: minValue(0) },
          },
          extra_tags: {},
        },
      },
    }
  },

  computed: {
    propertyTypes:        () => PROPERTY_TYPES,
    keyCollectionMethods: () => KEY_COLLECTION_METHODS,
    roomAmenities:        () => ROOM_AMENITIES,
    resortAmenities:      () => RESORT_AMENITIES,
  },
}
</script>

<style scoped lang="scss">
  fieldset {
    flex-basis: calc(33.333% - 2rem); // 1/3 - 2*gap
    flex-shrink: 0;
    min-width: 250px;
  }
  fieldset.half {
    flex-basis: calc(50% - 2rem);
  }
</style>
