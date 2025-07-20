class Api::VillasController < ApiController
  memoize(:villas, private: true) { with_current_domain(Villa).active }
  memoize(:villa,  private: true) { villas.includes(:route).find params[:id] }

  # GET /api/villas/:id(.json)
  def show
    raise ActiveRecord::RecordNotFound unless villa.active

    render json: VillaTeaserDecorator.wrap(current_currency, villa).merge({
      occupancies:         OccupancyExporter.from(villa).public_export,
      traveler_categories: villa.villa_price.traveler_price_categories,
    })
  end

  # GET /api/villas/facets(.json)
  def facets # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # TODO: das müsste man mal in ein Adapter-Objekt auslagern
    f = Category.includes(tags: :translations).each_with_object({}) { |cat, memo|
      next memo if %w[bedrooms bathrooms].include?(cat.name)
      next unless (set = cat.tags.select(&:filterable?)).any?

      data = {
        id:   cat.id,
        name: I18n.t(cat.name, scope: "category"),
        tags: set.map { |t| { id: t.id, name: t.description } },
      }

      data[:top]   = true if cat.name == "highlights"
      memo[cat.id] = data
    }

    vids = villas.pluck(:id, :pool_orientation).to_h
    v    = Tag.select("taggings.taggable_id as villa_id, array_agg(tags.id) as tags")
      .joins(:taggings)
      .where(filterable: true, category_id: f.keys, taggings: { taggable_type: "Villa", taggable_id: vids.keys })
      .where("taggings.taggable_id > 0") # wir haben müll in der DB
      .group("taggings.taggable_id")
      .map { |t| [t.villa_id, { id: t.villa_id, tags: t.tags }] }
      .to_h
    vids.each do |vid, loc|
      v[vid]     ||= { id: vid, tags: [] }
      v[vid][:loc] = loc
    end

    render json: {
      categories: f.values,
      villas:     v.values,
    }
  end

  # GET /api/villas/prefetch(.json)
  def prefetch
    render json: PathDecorator.wrap_all(villas.includes(:route)).to_json
  end

  # GET /api/villas/top(.json)
  def top_villas
    collection = villas.includes(:route, :geocoding)
      .sort_by(&:teaser_price)
      .reverse
      .first(params.fetch(:limit, 3).to_i)

    render json: VillaTeaserDecorator.wrap_all(current_currency, collection).to_json
  end

  # GET /api/villas/with-boat(.json)
  def with_boat
    collection = villas.includes(:route, :geocoding).where([
      "villas.id in (select distinct villa_id from boats)",
      "villas.id in (select distinct villa_id from boats_villas)",
    ].join(" or ")).order(Arel.sql("RANDOM()"))

    collection = collection.first(params.fetch(:limit, 3).to_i) if params.key?(:limit)

    render json: VillaTeaserDecorator.wrap_all(current_currency, collection).to_json
  end

  class PathDecorator < SimpleDelegator
    include Rails.application.routes.url_helpers
    include LocalizedRoutes::Helper

    def self.wrap_all(collection)
      collection.map { |object| new(object) }
    end

    def path
      villa_path(__getobj__)
    end

    def as_json(*)
      { name: name, path: path }
    end
  end
  private_constant :PathDecorator
end
