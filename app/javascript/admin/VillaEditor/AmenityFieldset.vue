<template>
  <fieldset class="form-horizontal">
    <legend>{{ label }}</legend>

    <AmenitySelect
        v-for="o, i in amenities"
        :key="o.category"
        v-bind="amenities[i]"
        @input="onSelect(i, $event)"
    />
  </fieldset>
</template>

<script>
import AmenitySelect from "./AmenitySelect.vue"

const DEFAULT_ROOM_AMENITIES = new Set([
  "RMA105", // Stove
  "RMA146", // Tables and chairs
  "RMA149", // Washer/dryer
  "RMA157", // Ceiling fan
  "RMA162", // Closets in room
  "RMA164", // Mini-refrigerator
  "RMA166", // Heating
  "RMA167", // Toaster
  "RMA2", // Air conditioning
  "RMA207", // Complimentary high speed internet in room
  "RMA234", // Luxury linen type
  "RMA245", // Private pool
  "RMA256", // Dining room seats
  "RMA270", // Seating area with sofa/chair
  "RMA32", // Dishwasher
  "RMA5020", // Spa Bath
  "RMA5085", // Dining Area
  "RMA5120", // Coffee Machine
  "RMA5126", // Dining Table
  "RMA5170", // Trash cans
  "RMA55", // Iron
  "RMA56", // Ironing board
  "RMA59", // Kitchen
  "RMA60", // Kitchen supplies
  "RMA6001", // Towels available
  "RMA6010", // Separate entrance
  "RMA6033", // Washer
  "RMA6034", // Dryer
  "RMA6035", // Hangers
  "RMA6036", // Laptop Friendly Workspace
  "RMA6039", // Patio
  "RMA6127", // Patio/Balcony
  "RMA6042", // Living room
  "RMA6045", // Outdoor furniture
  "RMA6046", // Outdoor dining area
  "RMA6058", // Linen
  "RMA6064", // Detached
  "RMA6095", // Dining spices
  "RMA6103", // Cooking basics
  "RMA6123", // Freezer
  "RMA6126", // High-Speed Wifi
  "RMA6140", // Barbeque Grill: Gas
  "RMA6141", // Barbeque Grill: Propane
  "RMA6144", // Premium Linens & Towels
  "RMA6145", // Kitchen Essentials
  "RMA6146", // In-unit Washer
  "RMA6157", // Private Dock
  "RMA68", // Microwave
  "RMA77", // Oven
  "RMA8", // Barbeque grills
  "RMA81", // Plates and bowls
  "RMA88", // Refrigerator
  "RMA89", // Refrigerator with ice maker
  "RMA98", // Silverware/utensils
  "RMA99", // Sitting area
])

const DEFAULT_BATHROOM_AMENITIES = new Set([
  "RMA11", // Bathroom amenities
  "RMA15", // Bathtub or Shower
  "RMA50", // Hairdryer
  "RMA5005", // Bath
  "RMA5027", // Free Toiletries
  "RMA5072", // Additional Toilet
  "RMA57", // Whirpool
  "RMA6037", // Essentials
  "RMA85", // Private bathroom
])

export default {
  components: {
    AmenitySelect,
  },

  props: {
    label:       { type: String, required: true },
    value:       { type: Array, default: () => ([]) },
    preselected: { type: Set, required: true },
    options:     { type: Map, required: true },
    kind:        { type: String, required: true }, // "resort" | "room"
  },

  data() {
    return {
      amenities: [],
      defaults:  [],
    }
  },

  watch: {
    value:   "rebuild",
    options: "rebuild",
  },

  mounted() {
    this.rebuild()
  },

  methods: {
    rebuild() {
      const amenities = [],
            value = new Set(this.value)

      for (const [category, byId] of this.options) {
        const curr = {
          category,
          options:     [],
          preselected: [],
          value:       [],
          defaults:    [],
        }
        for (const [id, { name }] of byId) {
          curr.options.push({ id, label: name })

          if (this.preselected.has(id)) {
            curr.preselected.push(name)
          }
          if (value.has(id)) {
            curr.value.push(id)
          }
        }
        if (this.kind === "room") {
          switch (category) {
          case "Room Amenities":
            curr.defaults = [...DEFAULT_ROOM_AMENITIES]
            break
          case "Bathroom":
            curr.defaults = [...DEFAULT_BATHROOM_AMENITIES]
            break
          }
        }

        amenities.push(curr)
      }

      this.amenities = amenities
    },

    onSelect(i, value) {
      this.amenities[i].value = value

      const v = []
      this.amenities.forEach(({ value }) => v.push(...value))
      this.$emit("input", [...new Set(v)])
    },
  },
}
</script>
