class TourController < ApplicationController
  skip_forgery_protection

  expose(:villa) { Villa.find params[:villa_id] }
  expose(:tour)  { Medium.where(type: ["Media::Pannellum", "Media::Tour"]).find_by id: params[:id] }

  expose(:tour_data) do
    # https://pannellum.org/documentation/reference/
    {
      panorama: media_url(tour, preset: :tour_lg,      only_path: true),
      preview:  media_url(tour, preset: :tour_preview, only_path: true),
      title:    villa.name,
    }.to_json
  end

  layout false

  def show
    if tour.nil?
      redirect_to villa_url(villa), status: :moved_permanently
      return
    end

    show_tour_site if tour.is_a?(Media::Tour)
    # else render :show (for Media::Pannellum)
  end

  private

  def show_tour_site
    rest = params[:rest].presence
    if rest.blank?
      redirect_to tour_direct_villa_tour_url(villa, tour, rest: "index.html"), status: :moved_permanently
      return
    end

    tour.unzip! unless tour.unzipped?
    if ["/", "index.html", "index.htm"].include?(rest)
      send_file tour.base_dir.join("index.html"), disposition: :inline
      return
    end

    path = tour.base_dir.join(params[:rest]).expand_path
    if path.to_s.start_with?(tour.base_dir.to_s)
      send_file path, disposition: :inline
      return
    end

    raise ActiveRecord::RecordNotFound
  end
end
