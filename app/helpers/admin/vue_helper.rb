module Admin
  module VueHelper
    def admin_media_gallery_config(rentable, media_type)
      endpoint = api_admin_media_path \
        rentable_type: rentable.class.table_name,
        rentable_id:   rentable.id,
        media_type:    media_type,
        format:        :json

      title = case media_type
      when "tours"      then "Touren v1"
      when "pannellums" then "Touren v2"
      when "videos"     then "Videos"
      else                   "Bilder"
      end

      {
        endpoint: endpoint,
        title:    title,
      }
    end

    def admin_boat_list_config(boats, current_boat_id = nil)
      list = boats.reorder(id: :asc).map { |boat|
        [
          boat.id,
          boat.model,
          boat.hidden,
          edit_admin_boat_path(boat),
          boat.formatted_matriculation_number,
        ]
      }

      {
        ":boats"   => list.to_json,
        ":current" => current_boat_id,
      }.compact
    end
  end
end
