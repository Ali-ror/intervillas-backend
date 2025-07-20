require "net/http"
require "uri"
require "tempfile"

class VideoPreviewWorker
  include Sidekiq::Worker

  Retry = Class.new StandardError
  private_constant :Retry

  def perform(video_id)
    v = Media::Video.find_by(id: video_id)
    return unless v # already deleted
    return if YoutubeVideo.update_thumbnail(v)

    # retry
    VideoPreviewWorker.perform_in(5.minutes, video_id)
  end
end
