# == Schema Information
#
# Table name: geocodings
#
#  id              :integer          not null, primary key
#  geocodable_type :string
#  geocodable_id   :integer
#  geocode_id      :integer
#
# Indexes
#
#  fk__geocodings_geocode_id         (geocode_id)
#  geocodings_geocodable_id_index    (geocodable_id)
#  geocodings_geocodable_type_index  (geocodable_type)
#  geocodings_geocode_id_index       (geocode_id)
#
# Foreign Keys
#
#  fk_geocodings_geocode_id  (geocode_id => geocodes.id)
#
class Geocoding < ApplicationRecord
  belongs_to :geocode
  belongs_to :geocodable, polymorphic: true

  def self.geocoded_class(geocodable)
    ActiveRecord::Base.send(:class_name_of_active_record_descendant, geocodable.class).to_s
  end

  def self.find_geocodable(geocoded_class, geocoded_id)
    geocoded_class.constantize.find(geocoded_id)
  end
end
