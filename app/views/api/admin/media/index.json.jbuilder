json.rentable_type rentable.class.name
json.rentable_id   rentable.id

json.create_url    api_admin_media_path(format: :json)
json.reorder_url   reorder_api_admin_media_path(format: :json)

json.media_items media, partial: 'medium', as: :medium

json.image_tags MyBookingPal::ImageTag.as_select_options if media_type == "images"
