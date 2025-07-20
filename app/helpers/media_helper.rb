module MediaHelper
  def media_name(medium)
    if (name = medium.description.presence || medium.de_description.presence)
      return name
    end

    fn = medium.filename
    File.basename(fn, File.extname(fn)) # basename without file ext
      .gsub(/\A[-._\d]*/, "")           # remove leading ids
      .gsub(/[-._]*(jpe?g|tiff?|png|gif)\z/, "") # trailing ext in filename (foo_jpeg.jpeg)
      .titlecase                        # proper formatting
  end

  def image_gallery_slides(images, thumbnail: true)
    images.map { |image|
      {
        xl:        media_url(image, preset: :gallery_xl),
        lg:        media_url(image, preset: :gallery_lg),
        md:        media_url(image, preset: :gallery_md),
        carousel:  media_url(image, preset: :carousel),
        thumbnail: (media_url(image, preset: :carousel_sm) if thumbnail),
        text:      image.description,
      }.compact
    }
  end

  def image_gallery(images, dots: false, fullscreen: true)
    content_tag "intervillas-gallery", nil,
      ":slides"        => image_gallery_slides(images).to_json,
      ":dots"          => dots,
      ":no-fullscreen" => !fullscreen
  end

  def panoramas_tag(villa)
    items = [*villa.pannellums, *villa.tours].map { |pan|
      {
        name: media_name(pan),
        url:  villa_tour_url(villa, pan),
      }
    }

    content_tag "intervillas-panoramas", nil,
      ":items" => items.to_json
  end

  def villa_videos_tag(villa)
    videos = villa.videos.active.joins(preview_attachment: :blob).map { |v|
      {
        name:    v.description.presence || v.de_description.presence || "Video",
        url:     v.video_url,
        preview: media_url(v, preset: :full),
      }
    }

    content_tag "intervillas-videos", nil,
      ":videos" => videos.to_json
  end

  def image_srcset(medium, preset:, only_path: false)
    ImgProxy::SUPPORTED_DPR_VALUES.map { |dpr|
      if dpr == 1
        [media_url(medium, preset: preset, only_path: only_path), "1x"]
      else
        [media_url(medium, preset: preset, only_path: only_path, dpr: dpr), "#{dpr}x"]
      end
    }
  end

  def image_srcset_tag(medium, preset:, alt: nil, only_path: false)
    image_tag media_url(medium, preset: preset, only_path: only_path),
      alt:     alt,
      srcset:  image_srcset(medium, preset: preset, only_path: only_path),
      loading: :lazy
  end
end
