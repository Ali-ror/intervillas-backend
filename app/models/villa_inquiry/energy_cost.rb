class VillaInquiry
  ENERGY_COST_OVERRIDE = 1 << 6
  ENERGY_COST_LEGACY   = 1 << 7

  concerning :EnergyCost do
    included do
      # smallint column (int16, signed), Postgres has not int8/uint8 type
      #
      #   0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
      #  +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
      #  |             unused            | L | O |    reserved   | Value |
      #  +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
      #
      # - Bit 8        L flag ("legacy")
      # - Bit 9        O flag ("override")
      # - Bits 10..14  reserved for future enum values (4..32)
      # - Bits 15..16  enum values (0..3)
      enum :energy_cost_calculation, {
        # base values (identical to Villa#energy_cost_calculation)
        defer:             0,
        usage:             1,
        flat:              2,
        included:          3,
        # overriden values behave similar to base values, but designate a locally
        # enforced value (i.e. admins have diverged from villa value, and changing
        # the villa will not update the local enum value)
        override_defer:    0 | ENERGY_COST_OVERRIDE, # 64
        override_usage:    1 | ENERGY_COST_OVERRIDE, # 65
        override_flat:     2 | ENERGY_COST_OVERRIDE, # 66
        override_included: 3 | ENERGY_COST_OVERRIDE, # 67
        # legacy value for existing bookings; functionally equivalent to :defer,
        # but also does not change when the villa has changed
        legacy:            0 | ENERGY_COST_OVERRIDE | ENERGY_COST_LEGACY, # 192
      }, prefix: true, scopes: false

      before_save :copy_energy_cost_from_villa
    end

    def energy_cost_calculation_overridden?
      energy_cost_calculation_for_database & ENERGY_COST_OVERRIDE != 0
    end

    def flat_energy_cost_calculation
      flat = energy_cost_calculation_for_database & ~ENERGY_COST_OVERRIDE & ~ENERGY_COST_LEGACY

      self.class.energy_cost_calculations.rassoc(flat)&.first
    end

    def copy_energy_cost_from_villa
      return if energy_cost_calculation_overridden?

      # XXX: using `villa&.energy_cost_calculation || "defer"` causes some
      #      seemingly unrelated specs to fail reliably!?
      self.energy_cost_calculation = villa_id ? villa.energy_cost_calculation : "defer"
    end
  end
end
