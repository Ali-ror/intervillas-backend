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

#
# Eine relativ große Zip-Datei mit Panorama-Tiles in unterschiedlichsten
# Formaten, inkl. Javascripten und Flash-Fallbacks
#
class Media::Tour < Medium
  attach_media :archive

  after_commit :unzip!, on: :create
  after_commit :cleanup, on: :destroy

  def cleanup
    base_dir.rmtree if unzipped?
    true
  rescue SystemCallError
    # ignore
  end

  def unzip!
    TourUnzipper.new(self).process!
  rescue TourUnzipper::Error => err
    Rails.logger.error err.message
    throw :abort
  end

  def unzipped?
    base_dir.exist?
  end

  def base_dir
    TourUnzipper::TARGET_BASE.join(id.to_s)
  end
end
