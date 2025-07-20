def str_to_js(str)
  '"' << str.gsub('"', "\\\"") << '"'
end

namespace :my_booking_pal do
  desc "Fetches the current list of amenities from an unofficial API and generates TypeScript code. Must run in production"
  task amenities: :environment do
    raw = if Rails.env.production?
      MyBookingPal.client.fetch_amenities
    elsif Rails.root.join("tmp/amenities.json").exist?
      # HACK: fetch with curl and save locally
      #
      #   curl -H "jwt: $JWT" -o tmp/amenities.json \
      #     https://mybookingpal.com/xml/services/rest/supplierapi/product/amenities
      #
      # Requires `MyBookingPal.client.send(:manager_token)` as $JWT.
      JSON.parse(Rails.root.join("tmp/amenities.json").read).fetch("data")
    else
      red = "\e[31;1m"
      rst = "\e[0m"

      $stderr.puts "#{red}This only works in production. Run something like#{rst}"
      $stderr.puts ""
      $stderr.puts "    ssh intervillas@intervillas-florida.com \\"
      $stderr.puts "      ./bundle exec rake my_booking_pal:amenities \\"
      $stderr.puts "      >app/javascript/admin/MyBookingPal/amenities.ts"
      $stderr.puts ""
      $stderr.puts "#{red}within in the project root directory.#{rst}"
      exit 1
    end

    sorted =

    entries = raw.sort_by { |row|
      row.values_at("displayCategory", "displayName")
    }.each_with_object(Hash.new { |h,k| h[k] = [] }) { |row, list|
      id, name, cat, resort = row.values_at("attributeCode", "displayName", "displayCategory", "displayRootLevel")
      list[cat]          << { cat:, id:, name:, resort: }
    }

    out = <<~TS
      /** @file Auto-generated via `rake my_booking_pal:amenities` - DO NOT EDIT */

      class Amenity {
        constructor(public id: string, public name: string, public category: string) {}
      }
      class ResortAmenity extends Amenity {}
      class RoomAmenity extends Amenity {}

      type AmenityByCategory = Map<string, Map<string, Amenity>>

      /** Amenities for the whole resort */
      export const RESORT_AMENITIES: AmenityByCategory = new Map()

      /** Amenities for the room */
      export const ROOM_AMENITIES: AmenityByCategory = new Map()

      // MyBookingPal has distinct amenities for the resort and the room (think: hotel
      // vs. room). This doesn't make much sense for Intervillas. We're partitioning
      // them nonetheless
      ;(<[category: string, [resort: boolean, id: string, name: string][]][]>[
    TS

    entries.each_pair do |cat, amenities|
      out << "  [#{str_to_js(cat)}, [\n"
      amenities.each do |row|
        id, name = row.values_at(:id, :name).map { str_to_js(_1) }
        out     << "    [#{row[:resort]}, #{id}, #{name}],\n"
      end
      out << "  ]],\n"
    end

    out << <<~TS
      ]).forEach(([category, amenities]) => {
        for (let i = 0, len = amenities.length; i < len; ++i) {
          const [resort, id, name] = amenities[i]
          const [target, klass] = resort
            ? [RESORT_AMENITIES, ResortAmenity]
            : [ROOM_AMENITIES, RoomAmenity]

          let byId = target.get(category)
          if (!byId) {
            byId = new Map<string, Amenity>()
            target.set(category, byId)
          }

          byId.set(id, new klass(id, name, category))
        }
      })
    TS

    puts out
  end
end
