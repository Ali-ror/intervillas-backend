json.id               medium.id
json.position         medium.position
json.active           medium.active
if medium.attachment_present?
  # new Media::Video records don't have a preview yet (will be fetched async.)
  json.filename       File.basename(medium.filename, File.extname(medium.filename))
  json.extname        File.extname(medium.filename).from(1).to_s
end
json.de_description   medium.de_description
json.en_description   medium.en_description

# for updates/destroy
json.url              api_admin_medium_path(id: medium.id, format: :json)

case medium
when Media::Image
  json.type           "image"
  json.thumbnail_url  media_path(medium, preset: :admin_thumb)
  json.preview_url    media_path(medium, preset: :carousel)
  json.download_url   rails_blob_path(medium.image, disposition: "attachment")
  json.image_tags     medium.image_tags

when Media::Pannellum
  json.type           "pannellum"
  json.thumbnail_url  media_path(medium, preset: :admin_thumb)
  json.preview_url    villa_tour_path(rentable, medium.id, iframe: "true")
  json.download_url   rails_blob_path(medium.panorama, disposition: "attachment")

when Media::Tour
  json.type           "tour"
  json.preview_url    villa_tour_path(rentable, medium.id, iframe: "true")
  json.download_url   rails_blob_path(medium.archive, disposition: "attachment")

when Media::Video
  json.type           "video"
  json.thumbnail_url  media_path(medium, preset: :full) if medium.attachment_present?
  json.video_url      medium.video_url
  json.refresh_url    refresh_api_admin_medium_path(id: medium.id, format: :json)

when Media::Slide
  json.type           "slide"
  json.thumbnail_url  media_path(medium, preset: :admin_thumb)
  json.preview_url    media_path(medium, preset: :carousel)
  json.download_url   rails_blob_path(medium.slide, disposition: "attachment")
else
  raise ArgumentError, "unexpected Medium: #{medium.inspect}"
end
