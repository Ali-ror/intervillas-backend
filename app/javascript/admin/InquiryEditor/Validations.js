import { required, minLength } from "vuelidate/lib/validators"

export function mustBeTrue(value) {
  return !!value
}

/**
 * Constructs a fresh base validation object for an inquiry, villa_inquiry,
 * and travelers. Optionally includes boat_inquiry validation.
 *
 * You are expected to extend the returned object as you need to see fit.
 * Used in ./{Inquiry,Booking}Editor.vue, see there for examples.
 *
 * @param {Boolean} withBoat whether or not to include validations for boat_inquiry
 */
export function newInquiryValidation(withBoat = false) {
  const energyCalculation = value => [
    "defer", "usage", "flat", "included", // from villa preset
    "override_defer", "override_usage", "override_flat", "override_included",
    "legacy", //
  ].includes(value)

  const inquiry = {
    villa_inquiry: {
      villa_id:   { required },
      start_date: { required },
      end_date:   { required },
      travelers:  {
        required,
        minLength: minLength(2),

        $each: {
          isValid: { required, mustBeTrue },
        },
      },
      energy_cost_calculation: { energyCalculation },
    },
  }

  if (withBoat) {
    inquiry.boat_inquiry = {
      boat_id:    { required },
      start_date: { required },
      end_date:   { required },
    }
  }
  return { inquiry }
}
