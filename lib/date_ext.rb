# date_easter:  calculate the day upon which Easter Sunday falls
#
# This program is free software!  You can copy, modify, share and
# distribute it under the same license as Ruby itself.
#
# Rick Scott
# rick@shadowspar.dyndns.org
#
# Tue Nov 28 22:57:01 EST 2006
#
#
# == Overview
#
# This module calculates the date upon which Easter falls, a date
# upon which many holidays in the Western world depend.
# It extends the Date class available in the Ruby standard library,
# adding the class method Date::easter(year) and the instance
# method easter().  It returns the correct date of Easter Sunday for
# the Gregorian calendar years 1583 to 4099.
#
# == Background
#
# Determining when Easter falls is a somewhat arcane process,
# largely due to the numerous adjustments that have been made to
# the Gregorian calendar in an attempt to `fit together' the
# cycles of the sun, moon, and earth.  Detailed discussion here
# would be somewhat pointless in light of the far superior
# resources available online -- see 'References', below, for some
# starting points.
#
# == References
#
# http://en.wikipedia.org/wiki/Computus
# http://www.phys.uu.nl/~vgent/easter/easter_text2a.htm
# http://users.chariot.net.au/~gmarts/eastcalc.htm

require "date"

class Date
  # rubocop:disable Layout/ExtraSpacing

  # Precomputed easter dates.
  EASTER = {
    # (2020..2035).each { printf "%d => %s\n", _1, Date.easter(_1).strftime("Date.new(%Y, %-m, %_d).freeze,") }
    2020 => Date.new(2020, 4, 12).freeze,
    2021 => Date.new(2021, 4,  4).freeze,
    2022 => Date.new(2022, 4, 17).freeze,
    2023 => Date.new(2023, 4,  9).freeze,
    2024 => Date.new(2024, 3, 31).freeze,
    2025 => Date.new(2025, 4, 20).freeze,
    2026 => Date.new(2026, 4,  5).freeze,
    2027 => Date.new(2027, 3, 28).freeze,
    2028 => Date.new(2028, 4, 16).freeze,
    2029 => Date.new(2029, 4,  1).freeze,
    2030 => Date.new(2030, 4, 21).freeze,
    2031 => Date.new(2031, 4, 13).freeze,
    2032 => Date.new(2032, 3, 28).freeze,
    2033 => Date.new(2033, 4, 17).freeze,
    2034 => Date.new(2034, 4,  9).freeze,
    2035 => Date.new(2035, 3, 25).freeze,
  }.freeze

  # rubocop:enable Layout/ExtraSpacing

  # Calculates the Date of Easter Sunday for the given `year`.
  # The Gregorian calendar is used.
  #
  # @param [Integer] year The year, for which Easter Sunday shall be computed.
  # @return [Date] Easter Sunday.
  def self.easter(year) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    return EASTER[year] if EASTER.key?(year)

    raise TypeError, "year must be an Integer, got #{year.class}" unless year.is_a? Integer
    raise ArgumentError, "Years before 1583 not supported"        if year < 1583
    raise ArgumentError, "Years after 4099 not supported"         if year > 4099

    golden_number      = (year % 19) + 1
    century            = (year / 100) + 1
    solar_correction   = (3 * century) / 4
    lunar_correction   = ((8 * century) + 5) / 25
    julian_epact       = (11 * (golden_number - 1)) % 30
    gregorian_epact    = (julian_epact - solar_correction + lunar_correction + 8) % 30
    days_fm_ve_to_pfm  = (23 - gregorian_epact) % 30
    days_fm_ve_to_pfm -= 1 if gregorian_epact == 24 || (gregorian_epact == 25 && golden_number > 11)
    vernal_equinox     = Date.new(year, 3, 21)
    paschal_full_moon  = vernal_equinox + days_fm_ve_to_pfm
    days_to_sunday     = 7 - paschal_full_moon.wday
    easter_sunday      = paschal_full_moon + days_to_sunday
    easter_sunday.freeze
  end

  # Return the Date of Easter Sunday for the year in which `self`
  # falls. The Gregorian calendar is used.
  #
  # @return [Date] Easter Sunday.
  def easter
    Date.easter(year)
  end
end
