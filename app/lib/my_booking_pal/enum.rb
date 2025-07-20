module MyBookingPal
  Enum = Struct.new(:id, :en, :de) do
    def self.as_select_options
      locale = I18n.locale.to_sym
      raise ArgumentError, "unexpected locale: #{locale}" unless %i[de en].include?(locale)

      @select_options ||= Hash.new { |h, k|
        h[k] = all
          .map { |a| [a.to_localized_s(k), a.id] }
          .sort_by { |opt| opt[0].downcase }
      }
      @select_options[locale]
    end
  end

  def self.loaded_enums
    @loaded_enums ||= begin
      amenities  = Set.new
      image_tags = Set.new
      source     = Rails.root.join("config/mybookingpal_tags.csv")

      CSV.foreach source, headers: true do |row|
        purpose, id, en, de = row.values_at("Purpose", "Name", "Description", "Beschreibung")

        case purpose
        when "amenities"
          amenities << Amenity.new(id, en, de)
        when "images"
          image_tags << ImageTag.new(id.to_i, en, de)
        end
      end

      {
        amenities:  amenities,
        image_tags: image_tags,
      }
    end
  end
end
