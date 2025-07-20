module Villas::Areas
  extend ActiveSupport::Concern

  included do
    has_many :areas, -> { includes([:tags]) },
      dependent: :destroy,
      autosave:  true

    has_many :bedrooms, -> {
      where category_id: Category.select(:id).find_by(name: :bedrooms)&.id
    }, class_name: "Area" do
      def build(attrs = {})
        super attrs.merge(category_id: Category.select(:id).find_by(name: :bedrooms).id)
      end
    end

    has_many :bathrooms, -> {
      where category_id: Category.select(:id).find_by(name: :bathrooms)&.id
    }, class_name: "Area" do
      def build(attrs = {})
        super attrs.merge(category_id: Category.select(:id).find_by(name: :bathrooms).id)
      end
    end
  end

  def bedrooms_count
    bedrooms.size
  end

  def beds_count
    bedrooms.sum(&:beds_count)
  end

  def bathrooms_count
    bathrooms.where.not(subtype: "gaestewc").count
  end

  def wcs_count
    wc_tag = Tag.where(name: "wc").first
    bathrooms.select { |bathroom|
      bathroom.tagged_with?(wc_tag)
    }.size
  end

  BEDS_AND_ROOMS_COUNT_QUERY = <<~SQL.squish.freeze
    with room_counts as (
      select  areas.villa_id
            , sum(areas.beds_count) as beds
            , count(areas.*)        as rooms
      from areas
      inner join categories on categories.id = areas.category_id
      inner join villas     on villas.id = areas.villa_id
      where categories.name = 'bedrooms'
        and villas.active = true
      group by areas.villa_id
    )
    select  2          as min_beds
          , max(beds)  as max_beds
          , 2          as min_rooms
          , max(rooms) as max_rooms
    from room_counts
  SQL
  private_constant :BEDS_AND_ROOMS_COUNT_QUERY

  class_methods do
    def minmax_beds_and_rooms_count
      res = find_by_sql(BEDS_AND_ROOMS_COUNT_QUERY)
      return [0, 0, 0, 0] unless res

      {
        beds:  %w[min_beds max_beds],
        rooms: %w[min_rooms max_rooms],
      }.transform_values { |vs|
        vs.map { |v| res[0].send(v) }
      }
    end
  end
end
