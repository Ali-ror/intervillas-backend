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

# Slides are used on the home page.
class Media::Slide < Medium
  attach_media :slide
end
