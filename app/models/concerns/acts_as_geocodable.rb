module ActsAsGeocodable
  # Make a model geocodable.
  #
  #  class Event < ActiveRecord::Base
  #    acts_as_geocodable
  #  end
  #
  # == Options
  # * <tt>:address</tt>: A hash that maps geocodable attirbutes (<tt>:street</tt>,
  #   <tt>:locality</tt>, <tt>:region</tt>, <tt>:postal_code</tt>, <tt>:country</tt>)
  #   to your model's address fields, or a symbol to store the entire address in one field
  # * <tt>:normalize_address</tt>: If set to true, you address fields will be updated
  #   using the address fields returned by the geocoder. (Default is +false+)
  # * <tt>:units</tt>: Default units-<tt>:miles</tt> or <tt>:kilometers</tt>-used for
  #   distance calculations and queries. (Default is <tt>:miles</tt>)
  #
  def acts_as_geocodable(options = {}) # rubocop:disable Metrics/AbcSize
    options = {
      address:           {
        street:      :street,
        locality:    :locality,
        region:      :region,
        postal_code: :postal_code,
        country:     :country,
      },
      normalize_address: false,
      distance_column:   "distance",
      units:             :miles,
    }.merge(options)

    class_attribute :acts_as_geocodable_options
    self.acts_as_geocodable_options = options

    define_callbacks :geocoding

    has_one :geocoding, -> { includes :geocode },
      as:        :geocodable,
      dependent: :destroy

    after_save :attach_geocode

    # Would love to do a simpler scope here, like:
    # scope :with_geocode_fields, includes(:geocoding)
    # But we need to use select() and it would get overwritten.
    scope :with_geocode_fields, -> {
      joins("JOIN geocodings ON #{table_name}.#{primary_key} = geocodings.geocodable_id
        AND geocodings.geocodable_type = '#{model_name}'
        JOIN geocodes ON geocodings.geocode_id = geocodes.id")
    }

    # Use ActiveRecord ARel style syntax for finding records.
    #
    #   Model.origin("Chicago, IL", within: 10)
    #
    # a +distance+ attribute indicating the distance
    # to the origin is added to each of the results:
    #
    #   Model.origin("Portland, OR").first.distance #=> 388.383
    #
    # == Options
    #
    # * <tt>origin</tt>: A Geocode, String, or geocodable model that specifies
    #   the origin
    # * <tt>:within</tt>: Limit to results within this radius of the origin
    # * <tt>:beyond</tt>: Limit to results outside of this radius from the origin
    # * <tt>:units</tt>: Units to use for <tt>:within</tt> or <tt>:beyond</tt>.
    #   Default is <tt>:miles</tt> unless specified otherwise in the +acts_as_geocodable+
    #   declaration.
    #
    scope :origin, ->(*args) {
      origin  = location_to_geocode(args[0])
      options = {
        units: acts_as_geocodable_options[:units],
      }.merge(args[1] || {})

      distance_sql   = sql_for_distance(origin, options[:units])
      distance_alias = acts_as_geocodable_options[:distance_column]
      scope          = with_geocode_fields.select("#{table_name}.*, #{distance_sql} AS #{distance_alias}")

      scope = scope.where("#{distance_sql} > #{options[:beyond]}") if options[:beyond]
      if options[:within]
        scope = scope.where(<<~SQL.squish, lat: origin.latitude, long: origin.longitude)
          (geocodes.latitude = :lat AND geocodes.longitude = :long) OR (#{distance_sql} <= #{options[:within]})
        SQL
      end
      scope
    }

    scope :near, -> { order(acts_as_geocodable_options[:distance_column] => :asc) }
    scope :far, -> { order(acts_as_geocodable_options[:distance_column] => :desc) }

    include ActsAsGeocodable::Model
  end

  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Find the nearest location to the given origin
      #
      #   Model.origin("Grand Rapids, MI").nearest
      #
      def nearest
        near.first
      end

      # Find the farthest location to the given origin
      #
      #   Model.origin("Grand Rapids, MI").farthest
      #
      def farthest
        far.first
      end

      # Convert the given location to a Geocode
      def location_to_geocode(location)
        case location
        when Geocode then location
        when ActsAsGeocodable::Model then location.geocode
        when String, Integer then Geocode.find_or_create_by_query(location.to_s)
        end
      end

      # Validate that the model can be geocoded
      #
      # Options:
      # * <tt>:message</tt>: Added to errors base (Default: Address could not be geocoded.)
      # * <tt>:allow_nil</tt>: If all the address attributes are blank, then don't try to
      #   validate the geocode (Default: false)
      # * <tt>:precision</tt>: Require a minimum geocoding precision
      #
      # validates_as_geocodable also takes a block that you can use to performa additional
      # checks on the geocode. If this block returns false, then validation will fail.
      #
      #   validates_as_geocodable do |geocode|
      #     geocode.country == "US"
      #   end
      #
      def validates_as_geocodable(options = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        options = options.reverse_merge message: "Address could not be geocoded.", allow_nil: false
        validate do |model|
          is_blank = model.to_location.attributes.except(:precision).all?(&:blank?)
          unless options[:allow_nil] && is_blank
            geocode = model.send(:attach_geocode)
            if !geocode ||
                (options[:precision] && geocode.precision < options[:precision]) ||
                (block_given? && yield(geocode) == false)
              model.errors.add(:base, options[:message])
            end
          end
        end
      end

      private

      def sql_for_distance(origin, units = acts_as_geocodable_options[:units])
        Graticule::Distance::Spherical.to_sql(
          latitude:         origin.latitude,
          longitude:        origin.longitude,
          latitude_column:  "geocodes.latitude",
          longitude_column: "geocodes.longitude",
          units:            units,
        )
      end
    end

    # Get the geocode for this model
    def geocode
      geocoding&.geocode
    end

    # Create a Graticule::Location
    def to_location
      Graticule::Location.new.tap do |location|
        %i[street locality region postal_code country].each do |attr|
          location.send("#{attr}=", geo_attribute(attr))
        end
      end
    end

    # Get the distance to the given destination. The destination can be an
    # acts_as_geocodable model, a Geocode, or a string
    #
    #   myhome.distance_to "Chicago, IL"
    #   myhome.distance_to "49423"
    #   myhome.distance_to other_model
    #
    # == Options
    # * <tt>:units</tt>: <tt>:miles</tt> or <tt>:kilometers</tt>
    # * <tt>:formula</tt>: The formula to use to calculate the distance. This can
    #   be any formula supported by Graticule. The default is <tt>:haversine</tt>.
    #
    def distance_to(destination, options = {})
      units   = options[:units] || acts_as_geocodable_options[:units]
      formula = options[:formula] || :haversine
      geocode = self.class.location_to_geocode(destination)
      self.geocode.distance_to(geocode, units, formula)
    end

    protected

    # Perform the geocoding
    def attach_geocode
      new_geocode = Geocode.find_or_create_by_location(to_location) if to_location.present?
      if new_geocode && geocode != new_geocode
        run_callbacks :geocoding do
          self.geocoding = Geocoding.new(geocode: new_geocode)
          update_address acts_as_geocodable_options[:normalize_address]
        end
      elsif !new_geocode && geocoding
        geocoding.destroy
      end
      new_geocode
    rescue Graticule::Error => err
      logger.warn err.message
    end

    def update_address(force = false) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return if geocode.blank?

      if acts_as_geocodable_options[:address].is_a? Symbol
        method = acts_as_geocodable_options[:address]
        send("#{method}=", geocode.to_location.to_s) if respond_to?("#{method}=") && (send(method).blank? || force)
      else
        acts_as_geocodable_options[:address].each do |attribute, method|
          send("#{method}=", geocode.send(attribute)) if respond_to?("#{method}=") && (send(method).blank? || force)
        end
      end

      self.class.without_callback(:save, :after, :attach_geocode) do
        save
      end
    end

    def geo_attribute(attr_key)
      if acts_as_geocodable_options[:address].is_a? Symbol
        attr_name = acts_as_geocodable_options[:address]
        attr_key == :street ? send(attr_name) : nil
      else
        attr_name = acts_as_geocodable_options[:address][attr_key]
        attr_name && respond_to?(attr_name) ? send(attr_name) : nil
      end
    end
  end
end
