module MyBookingPal
  class ImageTag < Enum
    def self.all
      MyBookingPal.loaded_enums.fetch(:image_tags)
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
