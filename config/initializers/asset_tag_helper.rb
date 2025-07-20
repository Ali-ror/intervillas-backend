# Monkeypatch ftw (naja ;-))
#
# Assets in public/data bekommen keine ID angehängt, um Google angeblich zu befriedigen
module ActionView::Helpers::AssetTagHelper

  private
  def rewrite_asset_path(source, path=nil)
    # keine asset ids für hochgeladene images
    if source =~ /^\/system\//
      source
    else
      if path && path.respond_to?(:call)
        return path.call(source)
      elsif path && path.is_a?(String)
        return path % [source]
      end

      asset_id = rails_asset_id(source)
      if asset_id.blank?
        source
      else
        source + "?#{asset_id}"
      end
    end
  end

end
