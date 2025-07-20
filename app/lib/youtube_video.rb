class YoutubeVideo < Struct.new(:video)
  def self.update_thumbnail(video)
    YoutubeVideo.new(video).fetch_thumbnail do |tmpfile|
      if tmpfile
        video.attach_media(io: File.open(tmpfile.path), filename: "preview.jpg")
        return true
      end
    end

    false
  end

  def fetch_thumbnail
    thumb_url = fetch_thumb_url(video)
    return unless thumb_url

    tmpfile = fetch_thumbnail_image(thumb_url)
    return if !tmpfile || tmpfile.size == 0

    yield tmpfile if block_given?
  ensure
    if tmpfile
      tmpfile.close
      tmpfile.unlink
    end
  end

  private

  # Fetches thumbnail URL of widest thumbnail image from YouTube API.
  def fetch_thumb_url(video)
    get(yt_api_url(video.video_id), "application/json") { |res|
      return unless res.is_a?(Net::HTTPOK)

      thumbs = JSON.parse(res.body).dig("items", 0, "snippet", "thumbnails")
      maxres = thumbs&.values&.max_by { |thumb| thumb["width"] || 0 }

      (maxres || {}).fetch("url", nil)
    }
  end

  # Downloads thumbnail image, returns Tempfile.
  def fetch_thumbnail_image(url)
    tmp = Tempfile.new("yt-preview-", nil, encoding: "binary")
    get(url, "image/*") do |res|
      unless res.is_a?(Net::HTTPOK)
        tmp.close
        tmp.unlink
        return nil
      end

      res.read_body { |chunk| tmp.write(chunk) }
    end
    tmp
  end

  def get(url, accept = "*/*")
    url = URI.parse(url) if url.is_a?(String)

    Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == "https") do |http|
      req           = Net::HTTP::Get.new url
      req["Accept"] = accept

      http.request(req) do |res|
        return yield res
      end
    end
  end

  def yt_api_url(video_id)
    api_key = Rails.application.credentials.google_maps_geocoding_key
    "https://youtube.googleapis.com/youtube/v3/videos?part=snippet&id=#{video_id}&key=#{api_key}"
  end
end
