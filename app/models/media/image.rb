# == Schema Information
#
# Table name: media
#
#  id          :integer          not null, primary key
#  active      :boolean          default(FALSE)
#  amenity_ids :integer          default([]), not null, is an Array
#  data        :jsonb            not null
#  description :string
#  parent_type :string           not null
#  position    :integer
#  type        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  parent_id   :integer          not null
#
# Indexes
#
#  index_media_on_parent_id_and_parent_type  (parent_id,parent_type)
#

# Images are descriptive photos of villas and boats.
class Media::Image < Medium
  attach_media :image

  after_commit on: %i[create update] do
    next unless parent_type == "Villa"
    next unless parent.booking_pal_product
    next unless %w[amenity_ids position active].any? { saved_changes.key?(_1) }

    # Image updates (especially reorderings) will create a stampede of remote
    # updates; using `bulk: true` will wait a moment, collect further updates,
    # and then create a single update request for MyBookingPal.
    parent.booking_pal_product.update_remote_images!(bulk: true)
  end

  concerning :Tags do
    def image_tags
      amenity_ids
    end

    def image_tags=(val)
      self.amenity_ids = (val || []).map(&:to_i)
    end
  end
end
