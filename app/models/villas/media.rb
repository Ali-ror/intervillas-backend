module Villas::Media
  extend ActiveSupport::Concern

  included do
    %w[image tour pannellum video].each do |medium|
      has_many medium.pluralize.to_sym, -> { order(position: :asc) },
        class_name: "Media::#{medium.classify}",
        as:         "parent"
    end

    has_one :main_image, -> { active.order(position: :asc).limit(1) },
      class_name: "Media::Image",
      as:         "parent"
  end

  def has_panoramas? # rubocop:disable Naming/PredicateName
    return @has_panoramas if defined? @has_panoramas

    @has_panoramas = Medium.where(
      parent_type: "Villa",
      parent_id:   id,
      type:        %w[Media::Tour Media::Pannellum],
    ).active.exists?
  end

  def has_videos? # rubocop:disable Naming/PredicateName
    return @has_videos if defined? @has_videos

    @has_videos = videos.active
      .joins(preview_attachment: :blob) # might not exits
      .exists?
  end
end
