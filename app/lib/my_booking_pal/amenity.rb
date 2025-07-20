module MyBookingPal
  class Amenity < Enum
    def self.all
      MyBookingPal.loaded_enums.fetch(:amenities)
    end

    def to_localized_s(locale)
      case locale.to_s
      when "de" then de
      when "en" then en
      else raise ArgumentError, "unsupported locale: #{locale}"
      end
    end
  end
end
