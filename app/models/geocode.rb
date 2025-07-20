# == Schema Information
#
# Table name: geocodes
#
#  id          :integer          not null, primary key
#  country     :string
#  latitude    :decimal(15, 12)
#  locality    :string
#  longitude   :decimal(15, 12)
#  postal_code :string
#  precision   :string
#  query       :string
#  region      :string
#  street      :string
#
# Indexes
#
#  geocodes_country_index      (country)
#  geocodes_latitude_index     (latitude)
#  geocodes_locality_index     (locality)
#  geocodes_longitude_index    (longitude)
#  geocodes_postal_code_index  (postal_code)
#  geocodes_precision_index    (precision)
#  geocodes_query_index        (query) UNIQUE
#  geocodes_region_index       (region)
#
class Geocode < ApplicationRecord
  has_many :geocodings, dependent: :destroy

  validates :query, uniqueness: true

  cattr_accessor :geocoder

  def distance_to(destination, units = :miles, formula = :haversine)
    return unless destination&.latitude && destination&.longitude

    Graticule::Distance.const_get(formula.to_s.camelize).distance(self, destination, units)
  end

  def geocoded?
    latitude.present? && longitude.present?
  end

  def self.find_or_create_by_query(query)
    find_by_query(query) || create_by_query(query)
  end

  def self.create_by_query(query)
    create geocoder.locate(query).attributes.merge(query: query)
  end

  def self.find_or_create_by_location(location)
    find_by_query(location.to_s) || create_from_location(location)
  end

  def self.create_from_location(location)
    create geocoder.locate(location).attributes.merge(query: location.to_s)
  rescue Graticule::Error => err
    logger.warn err.message
    nil
  end

  def precision
    Graticule::Precision.new(self[:precision])
  end

  def precision=(name)
    self[:precision] = name.to_s
  end

  def geocoded
    @geocoded ||= geocodings.collect { |geocoding| geocoding.geocodable }
  end

  def on(geocodable)
    geocodings.create(geocodable: geocodable)
  end

  def coordinates
    "#{longitude},#{latitude}"
  end

  def to_s
    coordinates
  end

  # Create a Graticule::Location
  def to_location
    Graticule::Location.new(attributes.except("id", "query"))
  end
end
