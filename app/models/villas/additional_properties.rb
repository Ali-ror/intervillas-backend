module Villas::AdditionalProperties
  extend ActiveSupport::Concern

  included do
    # update MyBookingPal prices if additional_properties[:los] has changed
    #
    # NOTE: a generic after_commit in ../villa.rb already updates the remote
    # product details an *any* change. This hook is *just* for LoS prices!
    after_commit on: :update do
      # if a remote product is present
      next unless booking_pal_product

      # and props were changed
      prop_changes = saved_changes.fetch("additional_properties", nil)
      next unless prop_changes

      # and LoS-related props were changed
      prev, curr = prop_changes.map { _1.fetch("los", {}) }
      next unless %w[min_stay max_stay advance_months surcharge].any? { prev[_1] != curr[_1] }

      # then refresh prices
      booking_pal_product.update_remote_prices!
    end
  end

  DEFAULT_ADDITIONAL_PROPERTIES = {
    property_type:    "PCT35",
    children_allowed: false,
    smoking_allowed:  false,
    pet_policy:       {
      allowed: false, # true | false | "request"
      fee:     "0",   # USD as decimal
    },
    internet_policy:  {
      available: false,
      type:      "wireless", # "wired" | "wireless"
      locations: "some",     # "all" | "office" | "some"
      fee:       "0",        # USD as decimal
    },
    parking_policy:   {
      available:   true,
      type:        "onsite",       # "onsite" | "nearby"
      private:     false,
      fee:         "0",            # USD as decimal
      fee_unit:    "stay",         # fee must be paid per: "hour" | "day" | "week" | "stay"
      reservation: "not_possible", # "not_needed" | "not_possible" | "required"
    },
    key_collection:   {
      method: "lock_box", # enum
      how:    "Please enter the code XXXX into the safe on the front door.", # free form
      when:   "On arrival/departure", # free form
    },
    los:              {
      min_stay:       7,  # 1..max_stay
      max_stay:       46, # min_stay+1 .. 46
      advance_months: 12, # 1..24
      surcharge:      10, # 0..n (percentage points)
    },
    extra_tags:       [],
  }.with_indifferent_access.freeze

  def additional_properties_with_defaults
    DEFAULT_ADDITIONAL_PROPERTIES.merge(additional_properties)
  end
end
