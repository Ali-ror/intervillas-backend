# Kümmert sich um Datei-Uploads (Bilder/Panoramen) für Häuser und Boote.
class Api::Admin::MediaController < ApplicationController
  include Admin::ControllerExtensions

  expose(:rentable) { rentable_class.find params[:rentable_id] }
  expose(:media)    { rentable.public_send(media_type).includes(:translations, MEDIA_MAPPING[media_type] => :blob) }

  helper_method :media_type

  expose(:medium) do
    if action_name == "create"
      media.new
    else
      media.find params[:id]
    end
  end

  def index
    # render index.json.jbuilder
  end

  def create
    return create_video if media_type == "videos"

    medium.send(:media_attachment).attach params[:blob]
    if medium.save
      medium.move_to_bottom
      render :create
      return
    end

    render_error :unprocessable_entity, medium.errors
  end

  def update
    pparams = case media_type
    when "images"
      params.require(:medium).permit(:active, :de_description, :en_description, :filename, image_tags: [])
    when "videos"
      video_params
    else
      params.require(:medium).permit(:active, :de_description, :en_description, :filename)
    end

    if medium.update(pparams)
      render :show
      return
    end

    render_error :unprocessable_entity, medium.errors
  end

  def refresh
    raise ActiveRecord::RecordNotFound if media_type != "videos"

    YoutubeVideo.update_thumbnail(medium)
    render :show
  end

  def destroy
    medium.destroy
    head :ok
  end

  # retrieves a list of Media IDs and updates their position
  # according to their index
  def reorder
    Medium.acts_as_list_no_update do
      current = media.unscoped
        .where(id: params[:sorted_medium_ids])
        .to_a

      Medium.transaction do
        pos = 0
        params[:sorted_medium_ids].map(&:to_i).each do |id|
          medium = current.find { |m| m.id == id }
          next unless medium

          medium.update(position: pos) if medium.position != pos
          pos += 1
        end
      end
    end

    head :ok
  end

  private

  def video_params
    params.require(:medium).permit(:active, :de_description, :en_description, data: {})
  end

  def create_video
    if medium.update(video_params)
      render :show
      return
    end

    render_error :unprocessable_entity, medium.errors
  end

  MEDIA_MAPPING = {
    "images"     => :image_attachment,
    "slides"     => :slide_attachment,
    "tours"      => :archive_attachment,
    "pannellums" => :panorama_attachment,
    "videos"     => :preview_attachment,
  }.freeze
  private_constant :MEDIA_MAPPING

  def render_error(status, errors)
    render :json, json: { errors: errors }, status: status
  end

  def media_type
    type = params[:media_type].presence
    raise ActiveRecord::RecordNotFound unless MEDIA_MAPPING.key?(type)

    type
  end

  def rentable_class
    case params[:rentable_type].presence
    when "villas"  then Villa
    when "boats"   then Boat
    when "domains" then Domain # not a rentable
    else raise ActiveRecord::RecordNotFound
    end
  end
end
