module LinkHelper
  def external_link_to(uri, content)
    link_to uri, target: "_blank", rel: "noopener noreferrer" do
      fa :external_link, text: content
    end
  end

  def link_to_play_store(uri)
    link_to uri, target: "_blank", rel: "noopener noreferrer" do
      tag.img(
        src:   vite_asset_path("images/app-stores/google.svg"),
        title: "Get it on Google Play",
        class: "m-3",
      )
    end
  end

  def link_to_app_store(uri)
    link_to uri, target: "_blank", rel: "noopener noreferrer" do
      tag.img(
        src:   vite_asset_path("images/app-stores/apple.svg"),
        title: "Get it on Google Play",
        class: "m-3",
      )
    end
  end
end
