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
class Media::Video < Medium
  attach_media :preview

  after_commit on: %i[create update] do
    if (ch = data_previous_change) && ch.dig(0, "url") != ch.dig(1, "url")
      VideoPreviewWorker.perform_async(id)
    end
  end

  def video_url
    data["url"]
  end

  def video_url=(value)
    if value.present?
      data["url"] = value
    else
      data.delete "url"
    end
  end

  def video_id
    case (url = URI.parse(video_url)).host
    when "www.youtube.com", "youtube.com", "m.youtube.com"
      # https://www.youtube.com/watch?v=VIDEOID
      params = CGI.parse url.query
      params.dig("v", 0)
    when "youtu.be"
      # https://youtu.be/VIDEOID
      url.path.split("/").last
    end
  rescue URI::InvalidURIError
    # ignore
  end
end
