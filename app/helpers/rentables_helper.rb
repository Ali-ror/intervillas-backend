module RentablesHelper
  def link_to_rentables
    rentables_string = rentable.model_name.plural
    link_to t("rentables.#{rentables_string}"), "/#{rentables_string}"
  end

  def link_to_rentable(rentable, external: false)
    opts = external ? { target: :_blank } : {}
    link_to rentable.display_name, rentable, opts
  end

  def link_to_boat_url(boat)
    return if (url = boat.url).blank?

    if url.downcase =~ /youtube/
      link_to fa(:youtube_play, text: "YouTube", class: "text-danger"), url, target: :_blank
    else
      link_to url, url, target: :_blank
    end
  end
end
