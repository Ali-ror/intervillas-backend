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

class Medium < ApplicationRecord
  translates :description
  include Digineo::I18n
  default_scope { includes(:translations) }

  include Media::Attachment

  # %q, not %Q, on purpose!
  ACTS_AS_LIST_SCOPE = %q(
        type = '#{type}'
    AND parent_type = '#{parent_type}'
    AND parent_id = #{parent_id}
  ).squish.freeze

  acts_as_list \
    scope:       ACTS_AS_LIST_SCOPE,
    top_of_list: 0 # defaults to 1

  validates :active,
    inclusion: { in: [true, false] }

  scope :active, -> { where active: true }

  belongs_to :parent, polymorphic: true
  alias villa parent
  alias boat parent
  alias domain parent

  def main?
    position == 0
  end

  def main!
    move_to_top
  end

  def self.slug(str, inst = nil)
    return inst&.cached_slug if str.nil?

    str.gsub(/\.\w{3}$/, "").gsub("_", "").to_slug.approximate_ascii.normalize.to_s
  end
end
